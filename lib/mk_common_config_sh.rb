#!/usr/bin/ruby
#
# Copyright (c) 2017, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Convert ruby constants in the CommonConfig module into sh/bash
# shell environment variable assignments.
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../etc", File.dirname(__FILE__))
require "common_config"

##############################################################################
class ShellVarMaker
  CONFIG_MOD = CommonConfig
  include CONFIG_MOD

  DEBUG = false
  NUM_LINES_PER_GROUP = 4
  VAR_TYPES = [String, Fixnum]

  # Export vars to the environment of subsequently executed shell commands
  WILL_EXPORT_SHELL_VARS = true
  EXPORT_STR = WILL_EXPORT_SHELL_VARS ? "export " : ""

  ############################################################################
  def self.show_shell_var_assignments
    puts "# This file was automatically created by #{File.basename(__FILE__)}."
    puts "# Variables below are derived from module '#{CONFIG_MOD}'."
    puts "# Variables are of the following types: #{VAR_TYPES.inspect}"
    puts "# Creation timestamp: #{Time.now.strftime('%a %Y-%m-%d %H:%M:%S %z')}"

    line_count = 0
    CONFIG_MOD.constants.sort.each do |const|
      line_count += 1
      puts if line_count % NUM_LINES_PER_GROUP == 1

      value = CONFIG_MOD.const_get(const)
      STDERR.puts "## #{const}|#{value.class}|#{value.inspect}" if DEBUG
      puts "#{EXPORT_STR}#{const}=#{value.inspect}" if VAR_TYPES.include?(value.class)
    end
  end
end

##############################################################################
# Main
##############################################################################
ShellVarMaker.show_shell_var_assignments

