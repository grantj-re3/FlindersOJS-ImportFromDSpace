<?xml version="1.0"?>
<!--
     Copyright (c) 2016, Flinders University, South Australia. All rights reserved.
     Contributors: Library, Corporate Services, Flinders University.
     See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).

     PURPOSE

     This XSLT script transforms a single *modified* DSpace Simple Archive
     Format (SAF) item into an XML "article" child-element suitable for
     batch importing into the Open Journal Systems (OJS) application.

     The "article" child-element is a repeating element within the
     "OJS 2.x native XML import/export format". In the OJS source,
     see plugins/importexport/native/sample.xml

     The modifications to the DSpace SAF are performed by the partner to
     this script - extend_dsxml.sh.
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
  <xsl:variable name="default_language" select="'en_US'" />
  <xsl:variable name="language" select="$default_language" />

  <xsl:variable name="ojs_subject_delimiter" select="';'" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
    <article>

      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element != 'subject']" />
      <xsl:apply-templates select="/extended_item/bitstreams/bitstream" />

      <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'subject']">
        <indexing>
          <subject locale="{$language}">
            <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'subject']" />
          </subject>
        </indexing>
      </xsl:if>

    </article>
  </xsl:template>

  <!-- 
       FIXME:
       Issues encountered while converting DSpace SAF XML format to
       OJS native import format.
       - DONE Split DSpace single author name field into firstname and surname.
       - DONE Ok for mandatory author email to be empty.
       - DONE Ok for author bio to be omitted.
       - DONE Assumes the first author is the primary contact (but might not
              really matter (yet) as we don't provide contact email).
       - DONE Assumes all contributors should be listed as authors.
       - DONE Combine multiple subjects into single subject field.
       - DONE Only migrate PDF bitstreams.
       - How to handle the language property?
         * DONE Assume default of en_US?
         * Read for every field but default if no dspace lang property?
         * As above but with will_force_default option and will_force_dspace option?
       - The following OJS elements are poorly populated: indexing
       - The following OJS elements are not populated: htmlgalley
  -->

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
  <!-- FIXME: I assume below that all contributors are authors (for a journal) -->
  <xsl:template match="dcvalue[@element = 'contributor']">
    <xsl:variable name="is_first" select="position()=1" />

    <author primary_contact="{$is_first}">
      <lastname>
        <xsl:value-of select="normalize-space(substring-before(., ','))" />
      </lastname>
      <firstname>
        <xsl:value-of select="normalize-space( substring-after(., ',') )" />
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
  <!-- FIXME: I assume one galley node per PDF? -->
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


