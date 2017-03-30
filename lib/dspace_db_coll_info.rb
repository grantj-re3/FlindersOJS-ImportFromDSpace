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
# Given a DSpace collection handle, gather the following info from the
# DSpace database:
# - Collection-level info
# - Item-level info; particularly regarding bitstreams
#
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../lib", File.dirname(__FILE__))
$: << File.expand_path("../etc", File.dirname(__FILE__))
$: << "#{ENV['HOME']}/.ds/etc"

require 'dspace_pg_utils'
require "common_config"

##############################################################################
class DSpaceDbCollectionInfo
  include DSpacePgUtils
  include CommonConfig

  LINE_DELIM = NEWLINE
  FIELD_DELIM = "|"

  REPORT_INFO = {
    ## Report key
    :collection_name => {
      :fpath   => "#{TEMP_DIR}/collection.psv",

      # Strings in this array must exactly match the columns in the :sql_fmt string.
      :columns => %w{
        collection_id  collection_hdl  collection_name  collection_desc
        parent_community_id parent_community_hdl parent_community_name
      },

      # sprintf() format string. "%s" will be populated with collection_hdl.
      :sql_fmt => <<-SQL_COLLECTION.gsub(/^\t*/, ''),
	select
	  col.collection_id,
	  h.handle collection_hdl,
	  col.name collection_name,
	  col.short_description collection_desc,

	  com.community_id parent_community_id,
	  (select handle from handle where resource_type_id=4 and resource_id=com.community_id) parent_community_hdl,
	  com.name parent_community_name
	from
	  collection col,
	  handle h,
	  community2collection com2col,
	  community com
	where col.collection_id=h.resource_id and h.resource_type_id=3 and h.handle='%s' and
	  col.collection_id=com2col.collection_id and com2col.community_id=com.community_id
      SQL_COLLECTION
    },
 

    ## Report key
    :bitstream_urls => {
      :fpath   => "#{TEMP_DIR}/bitstreams.psv",

      # Strings in this array must exactly match the columns in the :sql_fmt string.
      :columns => %w{
        bitstream_url  sequence_id  item_id  item_hdl  collection_id
        collection_hdl  bitstream_id  bitstream_format_id  mimetype  filename
      },

      # sprintf() format string. "%s" will be populated with collection_hdl.
      :sql_fmt => <<-SQL_BITSTREAM_URLS.gsub(/^\t*/, '')
	select
	  'http://dspace.flinders.edu.au/xmlui/bitstream/' || i.item_hdl || '/' || b.sequence_id || '/bitstream' bitstream_url,
	  b.sequence_id,
	  i.item_id,
	  i.item_hdl,
	  i.collection_id,
	  i.collection_hdl,
	  b.bitstream_id,
	  b.bitstream_format_id,
	  (select mimetype from bitstreamformatregistry where bitstream_format_id=b.bitstream_format_id) mimetype,
	  b.name filename

	from 
	  ( select
              item_id,
              (select handle from handle where resource_type_id=2 and resource_id=col2i.item_id) item_hdl,
              h.resource_id collection_id,
              h.handle collection_hdl
	    from
              collection2item col2i,
              (select resource_id, handle from handle where resource_type_id=3 and handle='%s') h
            where col2i.collection_id=h.resource_id
	  ) i,
	  bitstream b

	where
	 b.deleted='f' and b.bitstream_id in (
	  select bitstream_id from bundle2bitstream where bundle_id in (
	    select bundle_id from bundle where name='ORIGINAL' and bundle_id in (
	      select bundle_id from item2bundle i2bdl where i2bdl.item_id = i.item_id
	    )
	  )
	)
	order by item_hdl
      SQL_BITSTREAM_URLS
    },

  }

  attr_reader :collection_hdl, :reports

  ############################################################################
  # Constructor
  def initialize(collection_hdl)
    @collection_hdl = collection_hdl
    @reports = {}
    @items_by_hdl = {}
  end

  ############################################################################
  # Populate the report data-structure from database
  def populate_report(report_key)
    STDERR.puts "\nGet report '#{report_key}' for collection:  #{@collection_hdl}"
    rinfo = REPORT_INFO[report_key]
    fmt = rinfo[:sql_fmt]
    sql = sprintf(fmt, @collection_hdl)

    db_connect{|conn|
      conn.exec(sql){|result|
        if result.ntuples == 0
          STDERR.puts "Quitting: No records found for report '#{report_key}' with handle: '#{@collection_hdl}'"
          exit 3

        else
          @reports[report_key] = []
          result.each_with_index{|row,i|
            @reports[report_key][i] = rinfo[:columns].inject({}){|h,f| h[f] = row[f]; h}
          }
        end
      }
    }
  end

  ############################################################################
  def to_items_by_hdl
    @items_by_hdl = {}
    bs_list = @reports[:bitstream_urls]
    bs_list.each{|bs|
      item_hdl = bs["item_hdl"]
      @items_by_hdl[item_hdl] ||= []
      @items_by_hdl[item_hdl] << bs
    }
  end

  ############################################################################
  def verify_items_by_hdl
    @items_by_hdl.sort.each{|item_hdl, bitstreams|
      len = bitstreams.length
      STDERR.puts "WARNING: No bitstreams for item handle #{item_hdl}" if len == 0
      STDERR.puts "WARNING: More than one bitstream (#{len}) for item handle #{item_hdl}" if len > 1
      bitstreams.each{|b|
        mt = b["mimetype"]
        STDERR.puts "WARNING: Expected a PDF bitstream for item handle #{item_hdl}; found '#{mt}'" unless mt.match(/\/pdf$/i)
      }
    }
  end

  ############################################################################
  def to_xml_file_items_by_hdl
    @items_by_hdl.sort.each{|item_hdl, bitstreams|
      fpath = "#{TEMP_DIR}/item_#{item_hdl.sub('/', '_')}.xml"
      File.open(fpath, "w"){|fh|
        fh.puts "<item_level item_hdl=\"#{item_hdl}\">"
        bitstreams.each{|b|
          fh.puts "  <bitstream_record filename=\"#{b['filename']}\">"
          b.sort.each{|key,val| fh.printf "    <%s>%s</%s>\n", key, val, key}
          fh.puts "  </bitstream_record>"
        }
        fh.puts "</item_level>"
      }
    }
  end

  ############################################################################
  def to_item_level_xml_file
    to_items_by_hdl
    verify_items_by_hdl
    to_xml_file_items_by_hdl
  end

  ############################################################################
  # Generate a CSV (or other delimited) report. Return as a string.
  def report_to_s(report_key, with_header=true)
    lines = []
    rinfo = REPORT_INFO[report_key]
    lines << rinfo[:columns].join(FIELD_DELIM) if with_header

    @reports[report_key].each{|row|
      lines << rinfo[:columns].inject([]){|a,f| a << row[f]; a}.join(FIELD_DELIM)
    }
    lines.join(LINE_DELIM) + LINE_DELIM
  end

  ############################################################################
  # Write the generated report to a file.
  def write_report_to_file(report_key, with_header=true)
    str = report_to_s(report_key, with_header)
    File.open(REPORT_INFO[report_key][:fpath], 'w').write(str)
  end

=begin
  ############################################################################
  # Verify the command line arguments.
  def self.verify_command_line_args
    if ARGV.length != 1 || ARGV.include?('-h') || ARGV.include?('--help')
      STDERR.puts <<-MSG_COMMAND_LINE_ARGS.gsub(/^\t*/, '')
	Usage:  #{File.basename $0}  DSPACE_COLLECTION_HANDLE
	where the handle is of the form 'PREFIX/SUFFIX'. Eg.
	  #{File.basename $0}  123456789/9999
      MSG_COMMAND_LINE_ARGS

      exit 1
    end
  end

  ############################################################################
  # The main method for this class.
  def self.main
    verify_command_line_args
    collection_hdl = ARGV[0]
    coll = self.new(collection_hdl)

    REPORT_INFO.keys.sort{|a,b| a.to_s <=> b.to_s}.each{|rpt|
      coll.populate_report(rpt)
      #puts coll.report_to_s(rpt)
      coll.write_report_to_file(rpt)
    }
  end
=end

end

