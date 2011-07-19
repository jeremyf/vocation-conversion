#!/usr/bin/env ruby
require 'hpricot'
require 'yaml'
require 'logger'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'database')

Post.all.each do |post|
  content = Hpricot(post.content)
  (content/'img').each do |img_tag|
    # Remove the google tracking code.  No sense processing it.
    if img_tag.get_attribute('src') !~ /#{Regexp.escape("https://blogger.googleusercontent.com/tracker/")}/
      post.assets.create!(:source_url => img_tag.get_attribute('src'))
    end
  end
end