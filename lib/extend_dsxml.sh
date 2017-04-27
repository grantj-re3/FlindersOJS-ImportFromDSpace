#!/bin/sh
#
# Copyright (c) 2016-2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# USAGE
# extend_dsxml.sh [DC_FNAME] [CONTENTS_FNAME] [ITEM_HANDLE_FNAME]
#
# Assumes many shell variables have been exported or sourced from
# TOP_DIR/etc/common_config.sh (eg. FNAME_DC, FPATH_COLLECTION_LEVEL_XML).
#
# PURPOSE
#
# Make a new XML document which contains the dublin_core.xml content
# (from DSpace-SAF Simple Archive Format) plus customised extensions.
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

fpath_dc="$FNAME_DC"			# DSpace SAF dublin-core XML file
fpath_contents="$FNAME_CONTENTS"	# DSpace SAF contents file
fpath_item_handle="$FNAME_HANDLE"	# DSpace SAF handle file

[ ! -z "$1" ] && fpath_dc="$1"
[ ! -z "$2" ] && fpath_contents="$2"
[ ! -z "$3" ] && fpath_item_handle="$3"

##############################################################################
# Extract bitstream filenames
ruby_extr_bs_fnames='
  a = $_.chomp.split("\t")		# Split contents line by tab-char
  ext = a[0].gsub(/^.*\./, "")		# Extract file extension

  printf("<bitstream %s %s>%s</bitstream>\n",
    a[1].gsub(/^(bundle):(.*)$/, "\\1=\"\\2\""),
    "file_ext=\"#{ext.downcase}\"",
    a[0].encode2(:xml => :text)		# Filename may contain illegal XML chars (eg. &)
  )
'
bitstream_fnames_xml=`ruby -I "$LIB_DIR" -r object_extra -ne "$ruby_extr_bs_fnames" "$fpath_contents"`

# Point to item-level
item_hdl=`cat "$fpath_item_handle"`
item_hdl_mod=`echo "$item_hdl" |sed 's:/:_:'`
fpath_item_level_xml="$TEMP_DIR/item_${item_hdl_mod}.xml"

if [ ! -f "$fpath_item_level_xml" ]; then
  echo "ERROR: File not found; '$fpath_item_level_xml'" >&2
  echo "  Perhaps you are not processing the same collection as the DSpace Simple Archive Format?" >&2
  exit 4
fi

# Print the DSpace SAF XML (with extra/extended data). Comprises:
# - SAF Dublin Core metadata
# - Bitstream info derived from SAF "contents" file
# - Item level info derived from DB
# - Collection level info derived directly & indirectly from DB & other sources
cat <<-EO_XML
	<extended_item>
	`egrep -v "<\?xml " "$fpath_dc" | sed 's/^/  /'`

	  <contents>
	`echo "$bitstream_fnames_xml" | sed 's/^/    /'`
	  </contents>

	`sed 's/^/  /' "$fpath_item_level_xml"`

	`sed 's/^/  /' "$FPATH_COLLECTION_LEVEL_XML"`
	</extended_item>
EO_XML

