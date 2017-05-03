#!/bin/sh
#
# Copyright (c) 2016-2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# USAGE
#
# dspace_saf2ojs_wrap.sh  DSPACE_COLLECTION_HANDLE
# Eg:  ./dspace_saf2ojs_wrap.sh  123456789/9999
#
# PURPOSE
#
# To transform a collection of DSpace Simple Archive Format (SAF) items
# into a "collection" of articles suitable for batch importing into the
# Open Journal Systems (OJS) application. The batch importing format is
# "OJS 2.x native XML import/export format".
# 
# At the same time, this script will produce a "collection" of records
# suitable for batch importing into the Directory of Open Access Journals
# (DOAJ) https://doaj.org/.
#
# Links to further information regarding the target (OJS or DOAJ) XML formats
# can be found in the corresponding XSLT file in this repository.
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

BIN_DIR_TEMP=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
TOP_DIR=`cd "$BIN_DIR_TEMP/.." ; pwd`	# Absolute path of top dir
SH_CONFIG="$TOP_DIR/etc/common_config.sh"
$TOP_DIR/lib/mk_common_config_sh.rb > $SH_CONFIG	# Create shell environment vars (from ruby vars)
source $SH_CONFIG			# Source the shell environment vars

##############################################################################
# Attempt to get the publication date of the collection by getting the
# oldest dc.date.issued of all items in the collection.
get_collection_oldest_item_date() {
  # Date.parse() will convert dates like "2016-05-18T10:34:11Z" into "2016-05-18".
  # Years like "2016" will invoke the (empty) rescue clause below.
  ruby_extr_date_published='begin; puts Date.parse($_.split(/[<>]/)[2]) if $F[1]=="date" && $F[3]=="issued"; rescue; end'
  collection_date_pub=`ruby -F\" -r date -nae "$ruby_extr_date_published" $SAF_DIR/*/$FNAME_DC |sort |head -1`

  if ! echo "$collection_date_pub" |egrep -q "^(19|20)[0-9]{2}(-[0-9]{2}){2}$"; then
    echo "WARNING: Expected oldest item date of YYYY-MM-DD (where century is 19 or 20) but found '$collection_date_pub'" >&2
  fi
}

##############################################################################
# Attempt to extract the ISSN of the collection by extracting ISSN from every
# item; then use the ISSN which occurs most frequently (in case one has a typo)
get_collection_issn() {
  ruby_extr_issn='puts $_.split(/[<>]/)[2] if $F[1]=="identifier" && $F[3]=="issn"'
  collection_issn=`ruby -F\" -nae "$ruby_extr_issn" $SAF_DIR/*/$FNAME_DC |sort |uniq -c |sort -rn |head -1 |sed 's/^ *[0-9]* *//'`

  if ! echo "$collection_issn" |egrep -q "^[0-9]{4}-[0-9]{4}$"; then
    echo "WARNING: Expected ISSN to have 8-digits (with hyphen in center) but found '$collection_issn'" >&2
  fi
}

##############################################################################
get_more_collection_data() {
  get_collection_oldest_item_date
  get_collection_issn
  cat <<-MSG_COLLECTION_DATA > $FPATH_DSPACE_COLL_DATA_LOG
		# Derived from the oldest item-level dc.date.issued in the collection.
		Collection date published (oldest item): '$collection_date_pub'

		# Derived from the most frequently occurring item-level dc.identifier.issn in the collection.
		Collection ISSN (most frequent): '$collection_issn'

	MSG_COLLECTION_DATA
}

##############################################################################
# Get collection-level info from DSpace database then use the info to
# process collection-level components of OJS & DOAJ output-XML.
process_collection_level_info() {
  collection_hdl="$1"
  collection_date_pub="$2"
  collection_issn="$3"
  if [ "$collection_hdl" = "" ]; then
    echo "ERROR: Quitting. DSpace collection-handle not given on command line." >&2
    exit 1
  fi

  cmd="$DSPACE_COLLECTION_SCRIPT \"$collection_hdl\" \"$collection_date_pub\" \"$collection_issn\" > $FPATH_DSPACE_COLLECTION_SCRIPT_LOG 2>&1"
  eval $cmd
  res=$?

  if [ "$res" != 0 ]; then
    echo "ERROR: Quitting. Exit code was '$res'." >&2
    echo "  See log $FPATH_DSPACE_COLLECTION_SCRIPT_LOG" >&2
    echo "  Caused by command:  $cmd" >&2
    exit 2
  fi
}

##############################################################################
# Enhance the Dublin Core XML of each DSpace item so the file can be
# processed with XSLT later.
extend_dspace_saf_xml() {
  for dir in "$SAF_DIR"/*; do
    fpath_dc="$dir/$FNAME_DC"
    fpath_contents="$dir/$FNAME_CONTENTS"
    fpath_handle="$dir/$FNAME_HANDLE"
    fpath_dspace_ext="$dir/$FNAME_DSPACE_EXT"
    rel_bitstream_dir="`basename $SAF_DIR`/`basename $dir`/"

    if [ ! -e "$fpath_dc" ]; then	# No DSpace DC metadata file
      echo "WARNING: Skipping processing. Missing file '$fpath_dc'" >&2
      continue
    fi

    if [ ! -e "$fpath_contents" ]; then	# No DSpace contents file
      echo "WARNING: Skipping processing. Missing file '$fpath_contents'" >&2
      continue
    fi

    if [ ! -e "$fpath_handle" ]; then	# No DSpace handle file
      echo "WARNING: Skipping processing. Missing file '$fpath_handle'" >&2
      continue
    fi

    echo "Processing DSpace SAF item at '$rel_bitstream_dir'" >&2
    cmd1="$EXTEND_DSPACE_XML_SCRIPT \"$fpath_dc\" \"$fpath_contents\" \"$fpath_handle\" > \"$fpath_dspace_ext\""
    eval $cmd1
    res=$?

    [ $res != 0 ] && exit $res		# Exit on error
  done
}

##############################################################################
# Transform each DSpace item into an OJS article XML-element. Wrap them
# within /issues/issue elements.
build_ojs_xml() {
  (
    cat "$FPATH_OJS_IMPORT_BEGIN"	# Begin OJS-XML

    # Transform each DSpace item into an OJS article-element
    for dir in "$SAF_DIR"/*; do
      fpath_dspace_ext="$dir/$FNAME_DSPACE_EXT"
      rel_bitstream_dir="`basename $SAF_DIR`/`basename $dir`/"

      cmd2="xsltproc --stringparam rel_bitstream_dir \"$rel_bitstream_dir\" \"$DSPACE_TO_OJS_XSLT_SCRIPT\" \"$fpath_dspace_ext\" |egrep -v \"^<\?xml \""
      eval $cmd2
    done

    cat "$FPATH_OJS_IMPORT_END"		# End OJS-XML
  ) |
    xmllint --format - |
    sed 's/\(^.*<article[ >]\)/\n\1/' > "$FPATH_OJS_IMPORT"	# Add newline before each article-element

  echo "Created OJS2 file: $FPATH_OJS_IMPORT"
}

##############################################################################
build_doaj_xml() {
  (
    cat "$FPATH_DOAJ_IMP_BEGIN"		# Begin DOAJ-XML

    # Transform each DSpace item into an DOAJ record-element
    for dir in "$SAF_DIR"/*; do
      fpath_dspace_ext="$dir/$FNAME_DSPACE_EXT"
      rel_bitstream_dir="`basename $SAF_DIR`/`basename $dir`/"

      cmd2="xsltproc --stringparam rel_bitstream_dir \"$rel_bitstream_dir\" \"$DSPACE_TO_DOAJ_XSLT_SCRIPT\" \"$fpath_dspace_ext\" |egrep -v \"^<\?xml \""
      eval $cmd2
    done

    cat "$FPATH_DOAJ_IMP_END"		# End DOAJ-XML
  ) |
    xmllint --format - |
    sed 's/\(^.*<record[ >]\)/\n\1/' > "$FPATH_DOAJ_IMPORT"	# Add newline before each record-element

  echo "Created DOAJ file: $FPATH_DOAJ_IMPORT"
}

##############################################################################
# Main
##############################################################################
get_more_collection_data
process_collection_level_info "$1" "$collection_date_pub" "$collection_issn"
extend_dspace_saf_xml
build_ojs_xml
build_doaj_xml

echo "Check log file at: $FPATH_DSPACE_COLLECTION_SCRIPT_LOG"

