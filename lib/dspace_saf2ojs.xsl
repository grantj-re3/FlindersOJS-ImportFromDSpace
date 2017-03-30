<?xml version="1.0"?>
<!--
     Copyright (c) 2016-2017, Flinders University, South Australia. All rights reserved.
     Contributors: Library, Corporate Services, Flinders University.
     See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).

     PURPOSE

     This XSLT script transforms a single *modified* DSpace Simple Archive
     Format (SAF) item into an XML "article" child-element suitable for
     batch importing into the Open Journal Systems (OJS) application.

     The modifications to the DSpace SAF are performed by the partner to
     this script - extend_dsxml.sh.

     The "article" child-element is a repeating element within the
     "OJS 2.x native XML import/export format". In the OJS source,
     see plugins/importexport/native/sample.xml

     The sequence is apparently important for many of the XML elements in the DTD below.
     - https://github.com/pkp/ojs/blob/ojs-stable-2_4_8/plugins/importexport/native/native-sample.xml
     - https://github.com/pkp/ojs/blob/ojs-stable-2_4_8/plugins/importexport/native/native.dtd
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:date="http://exslt.org/dates-and-times"
>

  <xsl:output method="xml" version="1.0" indent="yes" />
  <xsl:strip-space elements="*" />

  <!--
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       We can pass parameters into this XSLT script from the command
       line using the xsltproc "param" or "stringparam" option. Eg.
         xsltproc \-\-stringparam rel_bitstream_dir dspace_saf/10001/ ...

       Relative file path from the SAF parent dir to the PDF/bitstream dir.
       The path must include the trailing "/" character.
       Typically "SAF_TOP_DIR/SAF_ITEM_DIR/".  Eg. "dspace_saf/10001/"
  -->
  <xsl:param name="rel_bitstream_dir" select="'./'" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- FIXME: I assume all metadata is in the language below. -->
  <xsl:variable name="default_language" select="'en_US'" />
  <xsl:variable name="language" select="$default_language" />

  <xsl:variable name="ojs_subject_delimiter" select="';'" />
  <xsl:variable name="space" select="' '" />
  <xsl:variable name="comma" select="','" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATE-BASED FUNCTIONS - can only return text or element-sequences -->
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
        <!-- Name format: "Surname, Givenname1 Givenname2 ... GivennameN" -->
        <xsl:value-of select="normalize-space( substring-before($person_name_raw, $comma) )" />
      </xsl:when>

      <xsl:when test="not(contains($person_name_raw, $space))">
        <!-- Name format: "Givenname" -->
        <xsl:value-of select="''" />
      </xsl:when>

      <xsl:otherwise>
        <!-- Name format: "Givenname1 Givenname2 ... GivennameN Surname" -->
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
        <!-- Name format: "Surname, Givenname1 Givenname2 ... GivennameN" -->
        <xsl:value-of select="normalize-space( substring-after($person_name_raw, $comma) )" />
      </xsl:when>

      <xsl:when test="not(contains($person_name_raw, $space))">
        <!-- Name format: "Givenname" -->
        <xsl:value-of select="$person_name_raw" />
      </xsl:when>

      <xsl:otherwise>
        <!-- Name format: "Givenname1 Givenname2 ... GivennameN Surname" -->
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
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
    <article>

      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element != 'subject']" />
      <xsl:apply-templates select="/extended_item/contents/bitstream" />

      <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'subject']">
        <indexing>
          <subject locale="{$language}">
            <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'subject']" />
          </subject>
        </indexing>
      </xsl:if>

    </article>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="dcvalue[
    @element != 'title' and
    @element != 'contributor' and
    @element != 'date' and
    @element != 'description' and
    @element != 'subject'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="bitstream[@bundle != 'ORIGINAL']" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'title']">
    <title locale="{$language}">
      <xsl:value-of select="." />
    </title>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'date']">
    <xsl:if test="@qualifier='accessioned'">
      <date_published>
        <xsl:value-of select="." />
      </date_published>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- 
       - I assume that all contributors are authors (for a journal).
       - I assume the first author is the primary contact. (Since we
         don't provide contact email, perhaps it is irrelevant.)
  -->
  <xsl:template match="dcvalue[@element = 'contributor']">
    <xsl:variable name="is_first" select="position()=1" />

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

    <author primary_contact="{$is_first}">
      <lastname>
        <xsl:value-of select="$surname" />
      </lastname>
      <firstname>
        <xsl:value-of select="$given_names" />
      </firstname>

      <email />
<!--
      <biography locale="{$language}" />
-->
    </author>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="dcvalue[@element = 'description']">
    <xsl:if test="@qualifier='abstract'">
      <abstract locale="{$language}">
        <xsl:value-of select="." />
      </abstract>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Merge multiple subject elements into a single (delimited) string -->
  <!-- Must be wrapped by a subject element. -->
  <xsl:template match="dcvalue[@element = 'subject']">
    <xsl:if test="position() != 1"> <xsl:value-of select="$ojs_subject_delimiter" /> </xsl:if>
    <xsl:value-of select="." />   
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!--
       - The DTD specifies one galley node per (PDF) file.
         * <!ELEMENT article (... (galley?, htmlgalley?)+, ...)>
         * <!ELEMENT galley (id*, label, file)>
       - FIXME: I assume every 'ORIGINAL' bitstream in the DSpace journal is a PDF.
  -->
  <xsl:template match="bitstream[@bundle = 'ORIGINAL']">
    <xsl:if test="@file_ext='pdf'">

      <galley locale="{$language}">
        <label>PDF</label>
        <file>

          <xsl:element name="href">
            <xsl:attribute name="src">
              <xsl:value-of select="concat($rel_bitstream_dir, .)" />
            </xsl:attribute>

            <xsl:attribute name="mime_type">
              <xsl:value-of select="'application/pdf'" />
            </xsl:attribute>
          </xsl:element>

        </file>
      </galley>

    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

