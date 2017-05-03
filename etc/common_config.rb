#
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Common config vars for ruby.
# Most of these vars are also copied so they can be used by sh/bash scripts.
#
# It is expected you will typically customise variables (and methods)
# labelled "CUSTOMISE" in:
# - common_config.rb (this script)
# - populate_tpl_from_coll_info.rb
# - dspace_saf2doaj_auto.rb
#
# BEWARE: You should take GREAT CARE if you choose to customise other
# variables as some files/directories are (recursively) deleted!
#
##############################################################################
module CommonConfig
  TOP_DIR  = File.expand_path("..", File.dirname(__FILE__))	# Top level dir
  BIN_DIR  = "#{TOP_DIR}/bin"
  ETC_DIR  = "#{TOP_DIR}/etc"
  LIB_DIR  = "#{TOP_DIR}/lib"

  PARENT_TEMP_DIR = "#{TOP_DIR}/working"
  # BEWARE: The directory pointed to by this symlink is recursively deleted!!!
  TEMP_DIR = "#{PARENT_TEMP_DIR}/collection"	# A symlink to the *temp* dir for current collection

  OUT_DIR_PARENT  = "#{TOP_DIR}/results"
  # BEWARE: The directory pointed to by this symlink is recursively deleted!!!
  OUT_DIR  = "#{OUT_DIR_PARENT}/current"	# A symlink to the *output* dir for current collection
  SAF_DIR  = "#{OUT_DIR}/dspace_saf"		# DSpace SAF dir

  # Executables
  EXTEND_DSPACE_XML_SCRIPT   = "#{LIB_DIR}/extend_dsxml.sh"
  DSPACE_COLLECTION_SCRIPT   = "#{LIB_DIR}/populate_tpl_from_coll_info.rb"
  DSPACE_TO_OJS_XSLT_SCRIPT  = "#{LIB_DIR}/dspace_saf2ojs.xsl"
  DSPACE_TO_DOAJ_XSLT_SCRIPT = "#{LIB_DIR}/dspace_saf2doaj.xsl"

  # Begin/end OJS XML which wraps the repeating article-elements
  FPATH_OJS_IMPORT_BEGIN_TPL = "#{ETC_DIR}/dspace_saf2ojs_begin.tpl.xml"
  FPATH_OJS_IMPORT_BEGIN     = "#{ETC_DIR}/dspace_saf2ojs_begin.xml"
  FPATH_OJS_IMPORT_END       = "#{ETC_DIR}/dspace_saf2ojs_end.xml"

  # Collection-level xml for inserting into SAF-extended xml
  FPATH_COLLECTION_LEVEL_XML_TPL = "#{ETC_DIR}/dspace_collection_level.tpl.xml"
  FPATH_COLLECTION_LEVEL_XML     = "#{ETC_DIR}/dspace_collection_level.xml"

  # Begin/end DOAJ XML which wraps the repeating record-elements
  FPATH_DOAJ_IMP_BEGIN = "#{ETC_DIR}/dspace_saf2doaj_begin.xml"
  FPATH_DOAJ_IMP_END   = "#{ETC_DIR}/dspace_saf2doaj_end.xml"

  FPATH_DSPACE_COLLECTION_SCRIPT_LOG = "#{TEMP_DIR}/collection_info_progress.log.txt"
  FPATH_DSPACE_COLL_DATA_LOG         = "#{TEMP_DIR}/collection_xdata.log.txt"
  FPATH_DSPACE_BITSTREAM_URLS        = "#{TEMP_DIR}/bitstreams.psv"
  FPATH_DSPACE_COLLECTION            = "#{TEMP_DIR}/collection.psv"

  # Output metadata from this script
  FPATH_OJS_IMPORT  = "#{OUT_DIR}/import_ojs.xml"
  FPATH_DOAJ_IMPORT = "#{OUT_DIR}/import_doaj.xml"

  # Item-level SAF file basenames
  FNAME_CONTENTS   = "contents"		# DSpace SAF contents file
  FNAME_HANDLE     = "handle"		# DSpace SAF handle file
  FNAME_DC         = "dublin_core.xml"	# DSpace SAF dublin-core XML file
  FNAME_DSPACE_EXT = "dc_extended.xml"	# Intermediate result of this script; XML based on FNAME_DC

  # Other
  URL_PREFIX_DSPACE_BITSTREAM = "http://dspace.flinders.edu.au/xmlui/bitstream/"	# CUSTOMISE

  ############################################################################
  # Constants required for the scheduled/auto DOAJ XML creation script
  ############################################################################
  SAF_SEQNUM_MIN = 10001

  DSPACE_TO_OJS_WRAP_SCRIPT = "#{LIB_DIR}/dspace_saf2ojs_wrap.sh"
  DSPACE_COMMAND_LINE_APP   = "#{ENV['HOME']}/dspace/bin/dspace"	# CUSTOMISE

  FPATH_DSPACE_SAF_EXPORT_LOG   = "#{TEMP_DIR}/dspace_saf_export.log.txt"
  FPATH_DSPACE_SAF_EXPORT_LOG2  = "#{TEMP_DIR}/dspace_saf_export.err.txt"

  FPATH_DSPACE_TO_OJS_WRAP_LOG  = "#{TEMP_DIR}/dspace_saf2ojs_wrap.log.txt"
  FPATH_DSPACE_TO_OJS_WRAP_LOG2 = "#{TEMP_DIR}/dspace_saf2ojs_wrap.err.txt"

  FPATH_DOAJ_XML_TARGET_TOP_DIR = "#{TOP_DIR}/testtarget"		# CUSTOMISE

  ############################################################################
  # Sanity check that a bitstream being deleted matches the expected path
  # Eg. .../results/current/dspace_saf/99999/...
  REGEX_DELETE_BITSTREAM_FPATH = /\/results\/current\/dspace_saf\/\d+\//

  # CUSTOMISE: OJS & DOAJ bulk import files are created via the DSpace
  # Simple Archive Format (SAF) export tool. This tool always creates a
  # copy of the bitstreams (typically full-text PDF files). These bistreams
  # can occupy a lot of disk space - especially if the collections contain
  # many items and if this app is processing a list of collections.
  # - The OJS import process requires the bitstreams hence we recommend
  #   you set the var below to false if your target app is OJS.
  # - DOAJ does not require the bitstreams (as it only requires the URL
  #   of the bitstreams in DSpace). Hence we recommend you set the var
  #   below to true if your target app is DOAJ.
  WILL_DELETE_BITSTREAMS = true

  # true  = Process 1 collection (ie. journal issue) by date
  # false = Process a list of collections
  WILL_PROCESS_1_COLLECTION_BY_DATE = true	# CUSTOMISE

  # Search for journal-issue month & year with this offset from today.
  # See DSpaceDbCommunityInfo.collection_name_regex()
  DAYS_OFFSET = 7				# CUSTOMISE if WILL_PROCESS_1_COLLECTION_BY_DATE == true

  HANDLE_PREFIX = "123456789"			# CUSTOMISE if WILL_PROCESS_1_COLLECTION_BY_DATE == false

  JOURNAL_KEY = :wic				# CUSTOMISE: Key for JOURNALS hash below

  # CUSTOMISE
  # - :community_hdl must be configured for your journal community handle
  # - :collection_regex_list only needs to be configured if you will process a
  #   list of collections ie. if WILL_PROCESS_1_COLLECTION_BY_DATE == false
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

end

