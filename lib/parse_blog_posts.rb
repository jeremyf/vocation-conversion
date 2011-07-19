#!/usr/bin/env ruby
require 'hpricot'
require 'yaml'
require 'logger'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'database')

init_db(true)

FileUtils.mkdir_p(File.join(File.dirname(__FILE__), '../log'))
log     = Logger.new(File.join(File.dirname(__FILE__), '../log', "#{File.basename(__FILE__)}.log"), 5, 10*1024)
source_filename = File.join(File.dirname(__FILE__), '../src/blog.xml')

doc = open(source_filename) { |file| Hpricot(file) }
log.info("Parsing #{source_filename}")

doc.search('entry').each_with_index do |entry, i|
  if i == 0
    log.info("Skipping first entry. It does not contain content for migration.")
  else
    Post.new { |post|
      post.categories = (entry/'category').select {|el| el.get_attribute('scheme') == 'http://www.blogger.com/atom/ns#'}.collect {|el| el.get_attribute('term')}
      post.author_name = (entry/"author name").inner_html.strip
      post.author_email = (entry/"author email").inner_html.strip
      post.blogger_id = (entry/"id").inner_html.strip
      post.content = (entry/"content").inner_html.strip
      post.published = (entry/"published").inner_html.strip
      post.updated = (entry/"updated").inner_html.strip
      post.thr_total = (entry/"thr:total").inner_html.strip.to_i
      thr_in_reply_to = (entry/"thr:in-reply-to").first
      if thr_in_reply_to.respond_to?(:get_attribute)
        post.thr_in_reply_to = thr_in_reply_to.get_attribute('ref').to_s.strip
      end
    }.save!
  end
end