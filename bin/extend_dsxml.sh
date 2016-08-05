#!/bin/sh
# Extend DSpace XML
# Usage:  extend_dsxml.sh [ DC_FNAME [CONTENTS_FNAME] ]
#
# Copyright (c) 2016, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# PURPOSE
#
# Make a new XML document which contains dublin_core.xml plus some
# customised extensions.
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

FPATH_DC="dublin_core.xml"	# DSpace SAF dublin-core XML file
FPATH_CONTENTS="contents"	# DSpace SAF contents file

[ ! -z "$1" ] && FPATH_DC="$1"
[ ! -z "$2" ] && FPATH_CONTENTS="$2"

##############################################################################
ruby_prog='
  a = $_.split				# Split contents line by white-space
  ext = a[0].gsub(/^.*\./, "")		# Extract file extension

  printf("<bitstream %s %s>%s</bitstream>\n",
    a[1].gsub(/^(bundle):(.*)$/, "\\1=\"\\2\""),
    "file_ext=\"#{ext.downcase}\"",
    a[0]
  )
'
bitstream_xml=`ruby -ne "$ruby_prog" "$FPATH_CONTENTS"`

cat <<-EO_XML
	<extended_item>
	`egrep -v "<\?xml " "$FPATH_DC" | sed 's/^/  /'`

	  <bitstreams>
	`echo "$bitstream_xml" | sed 's/^/    /'`
	  </bitstreams>
	</extended_item>
EO_XML

