#!/bin/sh
#
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# USAGE
#
# See usage info below.
#
# PURPOSE
#
# Generate some statistics (ie. counts) to help verify that the
# DOAJ XML file contains reasonable metadata. Other verification
# methods will be required, but this output should show if a
# record is missing a title, author name, etc.
#
##############################################################################
APP=`basename $0`

##############################################################################
# Function: count_xml_elements(var_name, xml_element_name, xml_fname)
# Count occurences of xml_element_name in file xml_fname. Assign the result to var_name.
count_xml_elements() {
  var_name="$1"
  xml_element_name="$2"
  xml_fname="$3"

  # Assumes 0 or 1 xml_element_names per line.
  cmd="$var_name=`egrep -c \"<$xml_element_name[> ]\" \"$xml_fname\"`"
  eval $cmd
}

##############################################################################
if [ $# = 0 ]; then
  echo "Usage:  $APP  IMPORT_DOAJ_XML1 [IMPORT_DOAJ_XML2 ...]" >&2
  echo "   Eg:  $APP  WiC*/import_doaj.xml" >&2
  exit 1
fi

# Heading line
printf "%-51s|%3s %3s %3s %3s|%3s %3s %3s %3s|%3s %3s %3s %3s|%3s %3s %3s\n" \
  Path \
  Rec Vol Iss ISN \
  Ttl Abs Typ URL \
  ID  Dat Pub Jnl \
  Lng Nam Kw

for fname in "$@"; do
  # Count each XML element of interest
  #			VAR_NAME		XML_ELEMENT		XML_FILE
  count_xml_elements	record			record			"$fname"
  count_xml_elements	volume			volume			"$fname"
  count_xml_elements	issue			issue			"$fname"
  count_xml_elements	issn			issn			"$fname"

  count_xml_elements	title			title			"$fname"
  count_xml_elements	abstract		abstract		"$fname"
  count_xml_elements	documentType		documentType		"$fname"
  count_xml_elements	fullTextUrl		fullTextUrl		"$fname"

  count_xml_elements	publisherRecordId	publisherRecordId	"$fname"
  count_xml_elements	publicationDate		publicationDate		"$fname"
  count_xml_elements	publisher		publisher		"$fname"
  count_xml_elements	journalTitle		journalTitle		"$fname"

  count_xml_elements	language		language		"$fname"
  count_xml_elements	name			name			"$fname"
  count_xml_elements	keyword			keyword			"$fname"

  # Show all counts for this file on 1 line
  printf "%-51s|%3s %3s %3s %3s|%3s %3s %3s %3s|%3s %3s %3s %3s|%3s %3s %3s\n" \
    "$fname" \
    $record            $volume          $issue        $issn \
    $title             $abstract        $documentType $fullTextUrl \
    $publisherRecordId $publicationDate $publisher    $journalTitle \
    $language          $name            $keyword

done

