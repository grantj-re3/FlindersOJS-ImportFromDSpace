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
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:date="http://exslt.org/dates-and-times"
>

  <xsl:output method="xml" version="1.0" indent="yes" />
  <xsl:strip-space elements="*" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- FIXME: I assume all metadata is in the language below. -->
  <xsl:variable name="default_language" select="'eng'" />
  <xsl:variable name="language" select="$default_language" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATE-BASED FUNCTIONS - can only return text or element-sequences -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template name="do_constant_fields">
    <language><xsl:value-of select="$language" /></language>
    <publisher>Flinders University</publisher>
  </xsl:template>


  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- TEMPLATES -->
  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->

  <!-- Root template -->
  <xsl:template match="/">
    <record>

      <xsl:call-template name="do_constant_fields" />
      <xsl:apply-templates select="/extended_item/collection_level/*" />
      <xsl:apply-templates select="/extended_item/item_level/bitstream_record" />

      <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'contributor']">
        <authors>
          <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'contributor']" />
        </authors>
      </xsl:if>

      <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[
        @element != 'contributor' and
        @element != 'subject'
      ]" />

      <xsl:if test="/extended_item/dublin_core/dcvalue[@element = 'subject']">
        <keywords language="{$language}">
          <xsl:apply-templates select="/extended_item/dublin_core/dcvalue[@element = 'subject']" />
        </keywords>
      </xsl:if>

    </record>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="dcvalue[
    @element != 'contributor' and
    @element != 'description' and
    @element != 'identifier' and
    @element != 'subject' and
    @element != 'title' and
    @element != 'type'
  ]" />

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- Do nothing -->
  <xsl:template match="collection_level/*[
    name() != 'parent_community_name' and
    name() != 'date_from_collection_name' and
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
    <title language="{$language}">
      <xsl:value-of select="." />
    </title>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!--
       - I assume that all contributors are authors.
       - FIXME: I assume that we will not format author names
         (eg. "Surname, Givenname") but copy whatever format is in DSpace.
  -->
  <xsl:template match="dcvalue[@element = 'contributor']">
    <author>
      <name><xsl:value-of select="." /></name>
    </author>
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
  <xsl:template match="dcvalue[@element = 'identifier']">
    <xsl:if test="@qualifier='issn'">
      <issn><xsl:value-of select="." /></issn>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- FIXME: I assume dc:type is ok for this field (as 'article' is given in example). -->
  <xsl:template match="dcvalue[@element = 'type']">
      <documentType><xsl:value-of select="." /></documentType>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <!-- This XSLT script assumes:
       - One bitstream per item.
       - The bitstream is a PDF.
       A warning is issued in associated scripts if these assumptions do not hold.
  -->
  <xsl:template match="bitstream_record">
    <xsl:if test="bitstream_url">
      <fullTextUrl format="pdf"><xsl:value-of select="bitstream_url" /></fullTextUrl>
    </xsl:if>
    <xsl:if test="item_hdl and sequence_id">
      <publisherRecordId><xsl:value-of select="concat(item_hdl, '/', sequence_id)" /></publisherRecordId>
    </xsl:if>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="parent_community_name">
    <journalTitle><xsl:value-of select="." /></journalTitle>
  </xsl:template>

  <!-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -->
  <xsl:template match="date_from_collection_name">
    <publicationDate><xsl:value-of select="." /></publicationDate>
  </xsl:template>

</xsl:stylesheet>

