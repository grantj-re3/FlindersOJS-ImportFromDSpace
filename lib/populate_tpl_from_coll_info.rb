#!/usr/bin/ruby
# 
#--
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
#
# PURPOSE
#
# Given a DSpace collection handle:
# - Gather extra item-level info from the DSpace database.
# - Gather extra collection-level info from DSpace database and other sources.
#
# - Create XML item-level info (for inclusion in the extended DSpace-SAF
#   XML file).
# - Create XML collection-level info from a template (for inclusion in
#   the extended DSpace-SAF XML file).
# - Create OJS issue-level (ie. DSpace collection-level) XML fragment
#   from a template.
#
##############################################################################
# Add dirs to the library path
$: << File.expand_path(".", File.dirname(__FILE__))
$: << File.expand_path("../etc", File.dirname(__FILE__))

require "date"
require "dspace_db_coll_info"
require "common_config"

##############################################################################
class SubstitutionTemplate
  include CommonConfig

  MONTH_NAME_REGEX = /^(January|February|March|April|May|June|July|August|September|October|November|December)$/i
  COLLECTION_NAME_REGEX = /^Volume +(\d+)[, ]+(No\.|Issue) +(\d+)[, ]+(\w+) +(\d{4})($|[^\d])/
  EXTRA_COLLECTION_FIELD_KEYS = [:volume_num, :issue_num, :month_name, :year, :issn, :date_pub, :date_from_collection_name]

  YEAR_RANGE = 1900..2050		# Valid journal publication year-range

  ############################################################################
  def initialize(collection_hdl, collection_fields, collection_date_pub, collection_issn)
    @collection_hdl = collection_hdl
    @collection_fields = collection_fields	# Gathered from DSpace DB
    @extra_collection_fields = {		# Hash values not gathered directly from DB
      :date_pub => collection_date_pub,
      :issn     => collection_issn,
    }
  end

  ############################################################################
  def gather_extra_collection_fields
    xcf = @extra_collection_fields
    @collection_fields["collection_name"].match(COLLECTION_NAME_REGEX)
    xcf[:volume_num] = $1
    xcf[:issue_num]  = $3
    xcf[:month_name] = $4
    xcf[:year]       = $5

    yyyy = xcf[:year].to_i
    if YEAR_RANGE.include?(yyyy) && xcf[:month_name].match(MONTH_NAME_REGEX)
      date_str = "1 #{xcf[:month_name]} #{yyyy}"	# Eg. "1 August 2016"
      xcf[:date_from_collection_name] = Date.parse(date_str).strftime("%Y-%m-%d")
    end

    EXTRA_COLLECTION_FIELD_KEYS.each{|k|
      STDERR.puts "WARNING: #{k} is empty" if xcf[k].nil? || xcf[k].empty?
    }
  end

  ############################################################################
  def populate_template(template_label, to_stdout=false)
    f = @collection_fields
    xcf = @extra_collection_fields

    if template_label == :ojs_import_template
      # OJS import xml wrapper/header for multiple articles/items
      fpath_tpl_in = SubstitutionTemplate::FPATH_OJS_IMPORT_BEGIN_TPL
      fpath_dest_out = SubstitutionTemplate::FPATH_OJS_IMPORT_BEGIN
      title = "#{f['parent_community_name']}, #{f['collection_name']}"
      tpl_fields = [
        title, f["collection_desc"], xcf[:volume_num], xcf[:issue_num],
        xcf[:year], xcf[:date_from_collection_name], xcf[:date_from_collection_name]
      ]
    elsif template_label == :dspace_collection_template
      # Collection level xml: Will be made available within "extended" SAF item xml file
      fpath_tpl_in = SubstitutionTemplate::FPATH_COLLECTION_LEVEL_XML_TPL
      fpath_dest_out = SubstitutionTemplate::FPATH_COLLECTION_LEVEL_XML
      tpl_fields = [
        f["collection_id"], f["collection_hdl"], f["collection_name"], f["collection_desc"],
        f["parent_community_id"], f["parent_community_hdl"], f["parent_community_name"], 
        xcf[:volume_num], xcf[:issue_num], xcf[:year], xcf[:month_name],
        xcf[:issn], xcf[:date_pub], xcf[:date_from_collection_name]
      ]
    else
      STDERR.puts "ERROR: Unrecognised template_label #{template_label.inspect}"
      exit 5
    end

    fmt = File.read(fpath_tpl_in)	# Get the template
    out_str = fmt % tpl_fields		# Populate the template with field values

    puts out_str if to_stdout
    File.open(fpath_dest_out, "w"){|fh| fh.puts out_str}
  end

end

##############################################################################
# Main
##############################################################################
collection_hdl = ARGV[0]
collection_date_pub = ARGV[1]
collection_issn = ARGV[2]

coll = DSpaceDbCollectionInfo.new(collection_hdl)
DSpaceDbCollectionInfo::REPORT_INFO.keys.sort{|a,b| a.to_s <=> b.to_s}.each{|rpt|
  coll.populate_report(rpt)
  coll.write_report_to_file(rpt)
}
coll.to_item_level_xml_file

tpl = SubstitutionTemplate.new(
  collection_hdl,
  coll.reports[:collection_name].first,
  collection_date_pub,
  collection_issn
)
tpl.gather_extra_collection_fields
tpl.populate_template(:ojs_import_template)
tpl.populate_template(:dspace_collection_template)

exit 0

