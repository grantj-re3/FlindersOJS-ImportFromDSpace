<?xml version="1.0"?>
<!--
     Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
     Contributors: Library, Corporate Services, Flinders University.
     See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).

     PURPOSE

     This XSLT script transforms a single *modified* DSpace Simple Archive
     Format (SAF) item into an XML "record" child-element suitable for
     batch importing into the Directory of Open Access Journals (DOAJ).

     The modifications to the DSpace SAF are performed by the partner to
     this script - extend_dsxml.sh.

     The "record" child-element is a repeating element within the
     DOAJ XML. See:
     - https://doaj.org/features#xml_upload
     - https://doaj.org/static/doaj/doajArticles.xsd
     - https://doaj.org/publishers#upload
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" version="1.0" indent="yes" />
  <xsl:strip-space elements="*" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- FIXME: I assume all metadata is in the language below. -->
  <xsl:variable name="default_language" select="'eng'" />
  <xsl:variable name="language" select="$default_language" />

  <xsl:variable name="space" select="' '" />
  <xsl:variable name="comma" select="','" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATE-BASED FUNCTIONS - can only return text or element-sequences -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template name="do_constant_fields">
    <language><xsl:value-of select="$language" /></language>
    <publisher>Flinders University</publisher>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template name="do_authors">
    <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'contributor']">
      <authors>
        <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'contributor']" />
      </authors>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template name="do_keywords">
    <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'subject']">
      <keywords language="{$language}">
        <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'subject']" />
      </keywords>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Recursive function to reverse the word-order of a string (based on
       space delimiter). Does not normalise-space.
  -->
  <xsl:template name="reverse_words">
    <xsl:param name="words" />

    <xsl:choose>
      <xsl:when test="contains($words, $space)">
        <!-- Reverse the words (ie. call me again) for words after the first space. -->
        <xsl:call-template name="reverse_words">
          <xsl:with-param name="words" select="substring-after($words, $space)" />
        </xsl:call-template>

        <!-- Then print the first word afterwards. -->
        <xsl:value-of select="concat($space, substring-before($words, $space))" />
      </xsl:when>

      <xsl:otherwise>
        <!-- No space remains so print the rest -->
        <xsl:value-of select="$words" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Get surname from a string in one of the following name formats:
       - Comma separated surname:  "Surname, Givenname1 Givenname2 ... GivennameN"
       - Single given name:        "Givenname"
       - Space separated names:    "Givenname1 Givenname2 ... GivennameN Surname"

       Does not handle double-barrelled (or triple-barrelled) surnames
       if those surnames are separated by space.
  -->
  <xsl:template name="get_surname">
    <xsl:param name="person_name" />

    <xsl:variable name="person_name_raw" select="normalize-space($person_name)" />
    <xsl:choose>
      <xsl:when test="contains($person_name_raw, $comma)">
        <!-- Input name format: "Surname, Givenname1 Givenname2 ... GivennameN" -->
        <xsl:value-of select="normalize-space( substring-before($person_name_raw, $comma) )" />
      </xsl:when>

      <xsl:when test="not(contains($person_name_raw, $space))">
        <!-- Input name format: "Givenname" -->
        <xsl:value-of select="''" />
      </xsl:when>

      <xsl:otherwise>
        <!-- Input name format: "Givenname1 Givenname2 ... GivennameN Surname" -->
        <xsl:variable name="names_rev">
          <xsl:call-template name="reverse_words">
            <xsl:with-param name="words" select="$person_name_raw" />
          </xsl:call-template>
        </xsl:variable>

        <!-- Return the first word (which is now the surname). -->
        <xsl:value-of select="substring-before($names_rev, $space)" />
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Get given names from a string in one of the following name formats:
       - Comma separated surname:  "Surname, Givenname1 Givenname2 ... GivennameN"
       - Single given name:        "Givenname"
       - Space separated names:    "Givenname1 Givenname2 ... GivennameN Surname"

       Does not handle given names of those with double-barrelled (or
       triple-barrelled) surnames if those surnames are separated by space.
  -->
  <xsl:template name="get_given_names">
    <xsl:param name="person_name" />

    <xsl:variable name="person_name_raw" select="normalize-space($person_name)" />
    <xsl:choose>
      <xsl:when test="contains($person_name_raw, $comma)">
        <!-- Input name format: "Surname, Givenname1 Givenname2 ... GivennameN" -->
        <xsl:value-of select="normalize-space( substring-after($person_name_raw, $comma) )" />
      </xsl:when>

      <xsl:when test="not(contains($person_name_raw, $space))">
        <!-- Input name format: "Givenname" -->
        <xsl:value-of select="$person_name_raw" />
      </xsl:when>

      <xsl:otherwise>
        <!-- Input name format: "Givenname1 Givenname2 ... GivennameN Surname" -->
        <xsl:variable name="names_rev">
          <xsl:call-template name="reverse_words">
            <xsl:with-param name="words" select="$person_name_raw" />
          </xsl:call-template>
        </xsl:variable>

        <!-- Omit the first word (ie. omit the surname). -->
        <xsl:variable name="givennames_rev" select="substring-after($names_rev, $space)" />

        <!-- Return the given names in original (not-reversed) order. -->
        <xsl:call-template name="reverse_words">
          <xsl:with-param name="words" select="$givennames_rev" />
        </xsl:call-template>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Get DOAJ whole name. person_name arg can be in one of the following formats:
       1a/ Comma separated surname:  "Surname, Givenname1 Givenname2 ... GivennameN"
       1b/ Ditto with suffix:        "Surname, Givenname1 Givenname2 ... GivennameN, Suffix"
       2a/ Single given name:        "Givenname"
       2b/ Ditto with suffix:        "Givenname Suffix"
       3a/ Space separated names:    "Givenname1 Givenname2 ... GivennameN Surname"
       3b/ Ditto with suffix:        "Givenname1 Givenname2 ... GivennameN Surname Suffix"
       where Suffix like Jnr., Snr., I, II, III, IV, etc.

       Assuptions:
       - No commas implies formats 2a, 2b, 3a, 3b. [These formats require no processing below.]
       - One comma implies format 1a.
       - Two commas implies format 1b.
       - More than 2 commas is invalid.

       Returns a string in one of the following name formats:
       - Single given name:        "Givenname"
       - Ditto with suffix:        "Givenname Suffix"
       - Space separated names:    "Givenname1 Givenname2 ... GivennameN Surname"
       - Space separated names:    "Givenname1 Givenname2 ... GivennameN Surname Suffix"

       URL https://doaj.org/features#xml_upload says:
         "The author name should be formatted First Name, Middle Name, Last Name"
       and gives example:
         <name>Fritz Haber</name>
       implying the commas are not supposed to be within the DOAJ XML.
  -->
  <xsl:template name="get_whole_name">
    <xsl:param name="person_name" />

    <xsl:variable name="person_name_raw" select="normalize-space($person_name)" />
    <xsl:choose>
      <xsl:when test="contains($person_name_raw, $comma)">
        <!-- Input name format: "Surname, Givenname1 Givenname2 ... GivennameN[, Suffix]" -->
        <xsl:variable name="surname">
          <xsl:call-template name="get_surname">
            <xsl:with-param name="person_name" select="." />
          </xsl:call-template>
        </xsl:variable>

        <xsl:variable name="given_names">
          <xsl:call-template name="get_given_names">
            <xsl:with-param name="person_name" select="." />
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="contains($given_names, $comma)">
            <!-- Input name format: "Surname, Givenname1 Givenname2 ... GivennameN, Suffix" -->
            <!-- Assume given_names component contains a suffix eg. "Joe, Jr." or "Joe, III" -->
            <xsl:variable name="name_suffix" select="normalize-space( substring-after($given_names, $comma) )" />
            <xsl:variable name="given_names_before_suffix" select="normalize-space( substring-before($given_names, $comma) )" />
            <xsl:value-of select="concat($given_names_before_suffix, $space, $surname, $space, $name_suffix)" />
          </xsl:when>

          <xsl:otherwise>
            <!-- Input name format: "Surname, Givenname1 Givenname2 ... GivennameN" -->
            <xsl:value-of select="concat($given_names, $space, $surname)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <!-- Input name format: "Givenname1 Givenname2 ... GivennameN Surname" -->
        <!-- Input name format: "Givenname1 Givenname2 ... GivennameN Surname Suffix" -->
        <!-- Input name format: "Givenname" -->
        <!-- Input name format: "Givenname Suffix" -->
        <xsl:value-of select="$person_name_raw" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
    <record>
      <!--
           The XSD specifies an order for the XML elements and DOAJ verifies
           against the XSD. We will use the following ordered subset of elements.
           - language, publisher
           - journalTitle, issn, publicationDate, volume, issue
           - publisherRecordId, documentType
           - title, authors, abstract, fullTextUrl, keywords
      -->
      <xsl:call-template name="do_constant_fields" />
      <xsl:apply-templates select="/extended_item/collection_level/parent_community_name" />
      <xsl:apply-templates select="/extended_item/collection_level/issn_frequent_item" />
      <xsl:apply-templates select="/extended_item/collection_level/date_from_collection_name" />
      <xsl:apply-templates select="/extended_item/collection_level/volume" />
      <xsl:apply-templates select="/extended_item/collection_level/issue" />

      <xsl:apply-templates select="/extended_item/item_level/bitstream_record/item_hdl" />
      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'type']" />

      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'title']" />
      <xsl:call-template name="do_authors" />
      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'description']" />
      <xsl:apply-templates select="/extended_item/item_level/bitstream_record/bitstream_url" />
      <xsl:call-template name="do_keywords" />
    </record>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="dcvalue[
    @element != 'contributor' and
    @element != 'description' and
    @element != 'subject' and
    @element != 'title' and
    @element != 'type'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="collection_level/*[
    name() != 'parent_community_name' and
    name() != 'date_from_collection_name' and
    name() != 'issn_frequent_item' and
    name() != 'volume' and
    name() != 'issue'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Use these element-names with the same element-name in the output doc -->
  <xsl:template match="volume|issue">
    <xsl:element name="{name()}">
      <xsl:value-of select="." />
    </xsl:element>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'title']">
    <xsl:if test="@qualifier='none'">
      <title language="{$language}">
        <xsl:value-of select="." />
      </title>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- I assume that all contributors are authors. -->
  <xsl:template match="dcvalue[@element = 'contributor']">
    <xsl:if test="normalize-space(.) != ''">

      <xsl:variable name="whole_name">
        <xsl:call-template name="get_whole_name">
          <xsl:with-param name="person_name" select="." />
        </xsl:call-template>
      </xsl:variable>

      <author>
        <name><xsl:value-of select="$whole_name" /></name>
      </author>

    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'description']">
    <xsl:if test="@qualifier='abstract'">
      <abstract language="{$language}">
        <xsl:value-of select="." />
      </abstract>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'subject']">
    <keyword><xsl:value-of select="." /></keyword>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- I assume dc:type is ok for this field (as 'article' is given in example). -->
  <xsl:template match="dcvalue[@element = 'type']">
      <documentType><xsl:value-of select="." /></documentType>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- This XSLT script assumes:
       - One bitstream per item.
       - The bitstream is a PDF.
       A warning is issued in associated scripts if these assumptions do not hold.
  -->
  <xsl:template match="bitstream_record/item_hdl">
    <xsl:if test="../sequence_id">
      <publisherRecordId><xsl:value-of select="concat(., '/', ../sequence_id)" /></publisherRecordId>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- This XSLT script assumes:
       - One bitstream per item.
       - The bitstream is a PDF.
       A warning is issued in associated scripts if these assumptions do not hold.
  -->
  <xsl:template match="bitstream_record/bitstream_url">
    <fullTextUrl format="pdf"><xsl:value-of select="." /></fullTextUrl>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="parent_community_name">
    <journalTitle><xsl:value-of select="." /></journalTitle>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="issn_frequent_item">
    <issn><xsl:value-of select="." /></issn>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="date_from_collection_name">
    <publicationDate><xsl:value-of select="." /></publicationDate>
  </xsl:template>

</xsl:stylesheet>

