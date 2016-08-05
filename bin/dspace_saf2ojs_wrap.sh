#!/bin/sh
# DSpace SAF to OJS - wrapper script
# dspace_saf2ojs_wrap.sh
#
# Copyright (c) 2016, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# PURPOSE
#
# To transform a collection of DSpace Simple Archive Format (SAF) items
# into a "collection" of articles suitable for batch importing into the
# Open Journal Systems (OJS) application. The batch importing format is
# "OJS 2.x native XML import/export format". In the OJS source, see
# plugins/importexport/native/sample.xml
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

APP=`basename $0`
APP_DIR_TEMP=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
APP_DIR=`cd "$APP_DIR_TEMP" ; pwd`	# Dir containing app (absolute path)
BASE_DIR=`cd "$APP_DIR/.." ; pwd`	# Base/top dir (parent of app)

# Executables
EXTEND_DSPACE_XML_SCRIPT="$APP_DIR/extend_dsxml.sh"
DSPACE_TO_OJS_XSLT_SCRIPT="$APP_DIR/dspace_saf2ojs.xsl"

# Begin/end OJS XML which wraps the repeating article-elements
FPATH_OJS_IMP_BEGIN="$BASE_DIR/etc/dspace_saf2ojs_begin.xml"
FPATH_OJS_IMP_END="$BASE_DIR/etc/dspace_saf2ojs_end.xml"

SAF_DIR="$BASE_DIR/results/dspace_saf"	# DSpace SAF dir
FPATH_OJS_IMPORT="$BASE_DIR/results/ojs_import.xml"	# Output of this script; OJS XML import format

FNAME_DC="dublin_core.xml"		# DSpace SAF dublin-core XML file
FNAME_CONTENTS="contents"		# DSpace SAF contents file
FNAME_DSPACE_EXT="ds_ext.xml"		# Intermediate result of this script; XML based on FNAME_DC

##############################################################################
(
  cat "$FPATH_OJS_IMP_BEGIN"		# Begin OJS-XML

  # Transform each DSpace item into an OJS article-element
  for dir in "$SAF_DIR"/*; do
    fpath_dc="$dir/$FNAME_DC"
    fpath_contents="$dir/$FNAME_CONTENTS"
    fpath_dspace_ext="$dir/$FNAME_DSPACE_EXT"
    rel_bitstream_dir="`basename $SAF_DIR`/`basename $dir`/"

    if [ ! -e "$fpath_dc" ]; then	# No DSpace metadata
      echo "WARNING: Skipping processing. Missing file '$fpath_dc'" >&2
      continue
    fi

    if [ ! -e "$fpath_contents" ]; then	# No DSpace bitstreams
      echo "WARNING: Skipping processing. Missing file '$fpath_contents'" >&2
      continue
    fi

    echo "Processing DSpace SAF item at '$rel_bitstream_dir'" >&2
    cmd1="$EXTEND_DSPACE_XML_SCRIPT \"$fpath_dc\" \"$fpath_contents\" > \"$fpath_dspace_ext\""
    eval $cmd1

    cmd2="xsltproc --stringparam rel_bitstream_dir \"$rel_bitstream_dir\" \"$DSPACE_TO_OJS_XSLT_SCRIPT\" \"$fpath_dspace_ext\" |egrep -v \"^<\?xml \""
    eval $cmd2

    echo
  done

  cat "$FPATH_OJS_IMP_END"		# End OJS-XML
) |
  xmllint --format - |
  sed 's/\(^.*<article \)/\n\1/' > "$FPATH_OJS_IMPORT"	# Add newline before each article-element

