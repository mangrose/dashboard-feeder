#!/usr/bin/env ruby
# encoding: utf-8

require 'irb'
require File.expand_path('../../lib/lib', __FILE__)
require File.expand_path('../../init', __FILE__)

if $0 == __FILE__
  IRB.start(__FILE__)
end
