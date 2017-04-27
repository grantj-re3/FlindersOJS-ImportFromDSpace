#!/usr/bin/ruby
#
#--
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
#
# PURPOSE
#
# To automatically find the latest issue of a journal (ie. DSpace
# community) and create the corresponding DOAJ XML metadata
# (eg. on a static web page) for upload to DOAJ. The latest issue is
# found by matching a regular expression containing date-info against
# the issue (ie. collection) name.
#
# In addition, this program can process a list of journal-issues
# (ie. collections) within the same journal (ie. community) if they
# have been configured within the JOURNALS hash below.
#
# This program assumes:
# - a journal corresponds to a DSpace community
# - each child journal-issue corresponds to a DSpace collection which is
#   a child of the above DSpace community
#
# HIGH LEVEL ALGORITHM
#
# - To be run as a Linux cron job each night for a few weeks around publication time.
# - Finds all collections (issues) within a community (journal).
# - Finds the latest issue by matching the collection name (ie. by month and year)
# - If found:
#   * Creates a DOAJ XML file for the issue (by invoking dspace_saf2ojs_wrap.sh)
#   * Copies (overwrites) DOAJ XML file & logs to a target location (eg. static web page).
#
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../etc", File.dirname(__FILE__))
$: << File.expand_path("../lib", File.dirname(__FILE__))
$: << "#{ENV['HOME']}/.ds/etc"

require "date"
require "fileutils"
require "dspace_pg_utils"
require "common_config"

##############################################################################
class DSpaceDbCommunityInfo
  include DSpacePgUtils		# FIXME: RESOURCE_TYPE_IDS[:community] in other scripts
  include CommonConfig

  # true  = Process 1 collection (ie. journal issue) by date
  # false = Process a list of collections
  WILL_PROCESS_1_COLLECTION_BY_DATE = true	# CUSTOMISE

  # Search for journal-issue month & year with this offset from today.
  # See self.collection_name_regex()
  DAYS_OFFSET = 7				# CUSTOMISE if WILL_PROCESS_1_COLLECTION_BY_DATE == true

  HANDLE_PREFIX = "123456789"			# CUSTOMISE if WILL_PROCESS_1_COLLECTION_BY_DATE == false

  # CUSTOMISE if WILL_PROCESS_1_COLLECTION_BY_DATE == false
  JOURNALS = {
    :wic => {
      :community_hdl => "#{HANDLE_PREFIX}/27255",
      :collection_regex_list => [
        # Regex must match only one collection (ie. journal issue)
        /February 2014/i,
          /August 2014/i,
        /February 2015/i,
          /August 2015/i,
        /February 2016/i,
          /August 2016/i,
      ],
    },

    :tnl => {
      :community_hdl => "#{HANDLE_PREFIX}/3206",
      :collection_regex_list => [
        # Regex must match only one collection (ie. journal issue)
        /November 2008/i,
             /May 2009/i,
        /November 2009/i,

             /May 2010/i,
        /November 2010/i,
             /May 2011/i,
        /November 2011/i,

             /May 2012/i,
        /November 2012/i,
             /May 2013/i,
        /November 2013/i,

             /May 2014/i,
        /November 2014/i,
             /May 2015/i,
        /November 2015/i,

             /May 2016/i,
        /November 2016/i, # Cannot extract volume & issue from Special Issue December 2016. Hence items mapped into November 2016.
      ],
    },
  }

  SECONDS_IN_1_DAY = 60 * 60 * 24		# Beware: Not true at start/end day of daylight savings

  # Strings in this array must exactly match the columns in the SQL_FMT_GET_COLLECTIONS string.
  COLUMNS_GET_COLLECTIONS = %w{
    community_id  community_hdl  community_name
    collection_id collection_hdl collection_name
  }

  # printf() format string. "%s" will be populated with community_hdl.
  SQL_FMT_GET_COLLECTIONS = <<-SQL_COLLECTIONS.gsub(/^\t*/, '')
	select
	  com2col.community_id,
	  h.handle community_hdl,
	  com.name community_name,

	  com2col.collection_id,
	  (select handle from handle where resource_type_id=#{RESOURCE_TYPE_IDS[:collection]} and resource_id=com2col.collection_id) collection_hdl,
	  (select name from collection where collection_id=com2col.collection_id) collection_name

	from
	  community2collection com2col,
	  community com,
	  handle h
	where
	  com.community_id = com2col.community_id and
	  com2col.community_id = h.resource_id and
	  h.resource_type_id=#{RESOURCE_TYPE_IDS[:community]} and
	  h.handle='%s'
	order by 4
  SQL_COLLECTIONS

  ############################################################################
  def initialize(community_hdl)
    @community_hdl =community_hdl
    @collections = []
  end

  ############################################################################
  def populate_collections
    sql = SQL_FMT_GET_COLLECTIONS % @community_hdl
    db_connect{|conn|
      conn.exec(sql){|result|
        if result.ntuples == 0
          STDERR.puts "Quitting: No collections found for (eJournal) community handle: '#{@community_hdl}'"
          exit 7

        else
          @collections = []
          c = @collections
          result.each_with_index{|row,i|
            c[i] = COLUMNS_GET_COLLECTIONS.inject({}){|h,f| h[f] = row[f]; h}
            c[i]['label'] = self.class.make_label(
              c[i]['community_name'], c[i]['collection_name'])
          }
        end
      }
    }
  end

  ############################################################################
  # The label is a shorthand representation of the community name + collection name
  def self.make_label(parent_comm_name, coll_name)
    label1 = parent_comm_name.split.map{|w| w[0,1]}.join	# First letter of each word
    label2 = coll_name.gsub(/[^\w]/, '')	# Discard all chars except alpha-numeric
    "#{label1}_#{label2}"
  end

  ############################################################################
  def find_collection_matching_name(collection_name_regex)
    puts "\nSearching for: #{collection_name_regex.inspect}"
    coll = @collections.find{|c| c["collection_name"].match(collection_name_regex)}
    puts "\nFound:         #{coll.inspect}"
    coll
  end

  ############################################################################
  # CUSTOMISE this method to match your DSpace collection name (which
  # corresponds to your journal issue).
  def self.collection_name_regex(days_offset)
    target_time = Time.now + SECONDS_IN_1_DAY * days_offset
    target_date_regex_str = Date.parse(target_time.to_s).strftime("%B +%Y")
    # Eg. "Volume X, Issue Y, November 2016" where month & year
    # corresponds to today's date (+/- offset number of days so a
    # scheduled job can look for a new collection (ie. journal
    # issue) a few days/weeks before or after the target month).
    /^ *Volume.*(Issue|No).* #{target_date_regex_str} *$/i
  end

  ############################################################################
  def self.delete_bitstreams(coll)
    bitstream_ext_to_delete = %w{pdf}
    puts "Deleting bitstreams in folder '#{coll['label']}' with extensions #{bitstream_ext_to_delete.inspect}"

    bitstream_ext_to_delete.each{|ext|
      # Assumes parent of dspace_saf folder (ie. 'current') is a symlink to coll['label']
      fglob = "#{SAF_DIR}/*/*.#{ext}{,.txt}"	# Matches XXXX.ext & XXXX.ext.txt
      # For case insensitive, use glob-flag File::FNM_CASEFOLD
      Dir.glob(fglob).each{|fpath|
        next unless fpath.match(/\/results\/current\/dspace_saf\/\d+\//)
        FileUtils.rm_f(fpath)
      }
    }
  end

  ############################################################################
  # FIXME: Check this method & common constants compatible with dspace_saf2ojs_wrap.sh
  # when run in stand-alone mode.
  def self.cleanup_dirs_files(coll)
    working_dir = "#{PARENT_TEMP_DIR}/#{coll['label']}"
    current_out_dir = "#{OUT_DIR_PARENT}/#{coll['label']}"

    if "#{coll['label'].strip}".empty?
      STDERR.printf "ERROR: Folder name ('label' key) in the following object is empty:\n  %s\n", coll.inspect
      exit 9
    else
      [
        # BEWARE: These directories are recursively deleted!!!
        [working_dir,     TEMP_DIR],
        [current_out_dir, OUT_DIR],
      ].each{|dir, symlink_to_dir|
        # FIXME: Check dir & symlink_to_dir have the same parent dir.

        # dir is a real directory holding files, etc.
        # symlink_to_dir is a symlink which points to dir.
        # Most references to the dir in other programs use the symlink,
        # however when process_collection_list() processes the next
        # collection, the symlink will move to the next collection but
        # the real dir holding files, etc will remain (eg. for analysis).
        FileUtils.remove_entry_secure(dir, true)
        FileUtils.rm_f(symlink_to_dir)
        FileUtils.mkdir_p(dir)
        FileUtils.ln_s(File.basename(dir), symlink_to_dir)
      }
    end

    # FIXME: Check above symlink exists
    FileUtils.mkdir_p(SAF_DIR)

    # FIXME: These are in etc dir so are overwritten for each run. Should they be moved to working dir?
    [FPATH_COLLECTION_LEVEL_XML, FPATH_OJS_IMPORT_BEGIN].each{|fname|
      FileUtils.remove_file(fname, true)
    }
  end

  ############################################################################
  def self.process_collection(coll)
    if coll.nil?
      STDERR.puts "Quitting: Within eJournal community with handle #{community_hdl},"
      STDERR.puts "  no collection was found matching #{regex.inspect}"
      exit 8
    else
      cleanup_dirs_files(coll)

      # DSpace Simple Archive Format (SAF) export
      cmd = "%s export -t COLLECTION  -i %s -d %s -n %d > %s 2> %s" %
        [DSPACE_APP, coll['collection_hdl'], SAF_DIR, SAF_SEQNUM_MIN,
        FPATH_DSPACE_SAF_EXPORT_LOG, FPATH_DSPACE_SAF_EXPORT_LOG2]
      `#{cmd}`
      res = $?

      unless "#{res}" == "0"
        STDERR.puts "DSpace SAF export failed with exit-code #{res}. See file #{File.basename(FPATH_DSPACE_SAF_EXPORT_LOG2)}"
        exit "#{res}".to_i
      end

      # Do DSpace SAF to DOAJ (& OJS) translation
      cmd = "%s %s > %s 2> %s" %
        [DSPACE_TO_OJS_WRAP_SCRIPT, coll['collection_hdl'],
        FPATH_DSPACE_TO_OJS_WRAP_LOG, FPATH_DSPACE_TO_OJS_WRAP_LOG2]
      `#{cmd}`
      res = $?

      unless "#{res}" == "0"
        STDERR.puts "DSpace SAF to DOAJ translation failed with exit-code #{res}. See file #{File.basename(FPATH_DSPACE_TO_OJS_WRAP_LOG2)}"
        exit "#{res}".to_i
      end

      # Copy files to target dir, FPATH_DOAJ_XML_TARGET_DIR
      target_dir = "#{FPATH_DOAJ_XML_TARGET_TOP_DIR}/#{coll['label']}"
      puts "\nTarget folder: '#{target_dir}'"
      FileUtils.mkdir_p(target_dir)

      src_files = [
        FPATH_DOAJ_IMPORT,

        FPATH_DSPACE_SAF_EXPORT_LOG2,
        FPATH_DSPACE_COLLECTION_SCRIPT_LOG,
        FPATH_DSPACE_TO_OJS_WRAP_LOG2,
=begin
        FPATH_DSPACE_SAF_EXPORT_LOG,
        FPATH_DSPACE_COLL_DATA_LOG,
        FPATH_DSPACE_TO_OJS_WRAP_LOG,
=end
      ]
      FileUtils.cp(src_files, target_dir)
      delete_bitstreams(coll)	# We don't need bitstreams for DOAJ
    end
  end

  ############################################################################
  def self.process_1_collection_by_date(community_hdl)
    comm = self.new(community_hdl)
    comm.populate_collections
    regex = collection_name_regex(DAYS_OFFSET)
    coll = comm.find_collection_matching_name(regex)
    self.process_collection(coll)
  end

  ############################################################################
  def self.process_collection_list(community_hdl, collection_regex_list)
    comm = self.new(community_hdl)
    comm.populate_collections
    collection_regex_list.each{|regex|
      coll = comm.find_collection_matching_name(regex)
      self.process_collection(coll)
    }
  end

end

##############################################################################
# Main
##############################################################################
journal_key = :wic
puts "\nJournal key:   #{journal_key}"
journal = DSpaceDbCommunityInfo::JOURNALS[journal_key]

if WILL_PROCESS_1_COLLECTION_BY_DATE
  # Process 1 collection (by date)
  DSpaceDbCommunityInfo.process_1_collection_by_date(journal[:community_hdl])

else
  # Process collection list for a given journal/community
  DSpaceDbCommunityInfo.process_collection_list(
    journal[:community_hdl],
    journal[:collection_regex_list]
  )
end

