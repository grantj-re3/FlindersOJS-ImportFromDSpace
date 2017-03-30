#
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Common config vars for ruby (and sh/bash)

module CommonConfig
  TOP_DIR  = File.expand_path("..", File.dirname(__FILE__))	# Top level dir
  BIN_DIR  = "#{TOP_DIR}/bin"
  ETC_DIR  = "#{TOP_DIR}/etc"
  LIB_DIR  = "#{TOP_DIR}/lib"
  TEMP_DIR = "#{TOP_DIR}/working"

  OUT_DIR  = "#{TOP_DIR}/results"
  SAF_DIR  = "#{OUT_DIR}/dspace_saf"	# DSpace SAF dir

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

  FPATH_DSPACE_COLLECTION_SCRIPT_LOG = "#{OUT_DIR}/collection_info_progress.log"
  FPATH_DSPACE_COLL_DATA_LOG         = "#{TEMP_DIR}/collection_xdata.log"
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
end

