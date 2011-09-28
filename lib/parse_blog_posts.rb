#!/usr/bin/env ruby

require 'hpricot'
require 'yaml'
require 'logger'
require 'fileutils'
require 'rest_client'
require 'highline'
require 'fastercsv'
require "highline/import"

require File.join(File.dirname(__FILE__), 'database')

UPLOAD_SCHEME = 'https'
HOST = 'vocation.conductor.nd.edu'

def net_id
  @net_id ||= ask(%(<%= color("Net ID: ", :black, :on_yellow)%>))
end

def password
  @password ||= ask(%(<%= color("Password: ", :black, :on_yellow)%>)) { |q| q.echo = "*" }
end

def with_rest_timeout_retry(counter)
  retried_counter = 0
  begin
    yield
  rescue RestClient::RequestTimeout => e
    if retried_counter < counter
      retried_counter += 1
      retry
    else
      raise e
    end
  end
end

# init_db(true)
#
FileUtils.mkdir_p(File.join(File.dirname(__FILE__), '../log'))
log     = Logger.new(File.join(File.dirname(__FILE__), '../log', "#{File.basename(__FILE__)}.log"), 5, 10*1024)
source_filename = File.join(File.dirname(__FILE__), '../src/blog.xml')
#
# doc = open(source_filename) { |file| Hpricot(file) }
log.info("Parsing #{source_filename}")
#
# doc.search('entry').each_with_index do |entry, i|
#   if i == 0
#     log.info("Skipping first entry. It does not contain content for migration.")
#   else
#     Post.new { |post|
#       post.categories = (entry/'category').select {|el| el.get_attribute('scheme') == 'http://www.blogger.com/atom/ns#'}.collect {|el| el.get_attribute('term')}
#       post.author_name = (entry/"author name").inner_html.strip
#       post.author_email = (entry/"author email").inner_html.strip
#       post.title = (entry/"title").inner_html.strip
#       post.blogger_id = (entry/"id").inner_html.strip
#       post.content = (entry/"content").inner_html.strip.gsub("&gt;", '>').gsub('&lt;', "<")
#       post.published = (entry/"published").inner_html.strip
#       post.updated = (entry/"updated").inner_html.strip
#       post.from_url = (entry/"link[@rel='alternate'][@type='text/html']").first.get_attribute('href')
#       post.thr_total = (entry/"thr:total").inner_html.strip.to_i
#       thr_in_reply_to = (entry/"thr:in-reply-to").first
#       if thr_in_reply_to.respond_to?(:get_attribute)
#         post.thr_in_reply_to = thr_in_reply_to.get_attribute('ref').to_s.strip
#       end
#     }.save!
#   end
# end
#
# Category.all.each do |category|
#   with_rest_timeout_retry(3) do
#     begin
#       RestClient.post(
#       File.join("#{UPLOAD_SCHEME}://#{net_id}:#{password}@#{HOST}", '/admin/categories'),
#       {'category' => category.conductor_attributes, 'without_expire' => 'true'},
#       :accept => :html
#       )
#     rescue RestClient::Found => e
#       uri = URI.parse(e.response.headers[:location])
#       category.update_attribute(:conductor_admin_path, uri.path)
#       log.info("Posted blog post #{category.name}")
#     rescue Exception => e
#       require 'ruby-debug'; debugger; true;
#     end
#   end
# end
#
# Post.all.each do |post|
#   content = Hpricot(post.content)
#   (content/'img').each do |img_tag|
#     source_url = img_tag.get_attribute('src')
#     # Remove the google tracking code.  No sense processing it.
#     if source_url !~ /#{Regexp.escape("https://blogger.googleusercontent.com/tracker/")}/
#       post.assets.create!(:source_url => source_url)
#       log.info("Found Asset #{source_url}")
#     end
#   end
# end
#
# Asset.all.each do |asset|
#   dirname = File.join(File.dirname(__FILE__), "../tmp/assets/#{asset[:id]}/")
#   FileUtils.mkdir_p(dirname)
#   temp_filename = File.join(dirname, "#{File.basename(asset.source_url.to_s)}")
#   with_rest_timeout_retry(3) do
#     response = RestClient.get(asset.source_url)
#     File.open(temp_filename, 'w+') do |file|
#       file.puts response.body
#     end
#     log.info("Downloaded Asset #{asset.source_url}")
#   end
#   asset.update_attribute(:local_filename, temp_filename)
# end
#
# # Upload asset
# Asset.all.each do |asset|
#   with_rest_timeout_retry(3) do
#     begin
#       RestClient.post("#{UPLOAD_SCHEME}://#{net_id}:#{password}@#{File.join(HOST, "/admin/assets")}",
#       {"asset" => { "file" => File.new(asset.local_filename), 'tag' => 'imported' }, 'without_expire' => 'true', 'publish' => '1'}
#       )
#     rescue RestClient::Found => e
#       uri = URI.parse(e.response.headers[:location])
#       asset_id = uri.path.sub(/^\/admin\/assets\/(\d+)(\/.*)?/, '\1')
#       asset.update_attribute(:conductor_asset_id, asset_id)
#       log.info("Uploaded Asset #{asset.source_url}")
#     rescue RestClient::InternalServerError => e
#       log.error("Unable to Upload Asset #{asset.source_url}\n\t#{e}")
#     end
#   end
# end
#
# # Update content
# Asset.all.each do |asset|
#   asset.post.tap do |post|
#     post.update_attribute(:content, post.content.gsub(asset.source_url, asset.conductor_path))
#   end
# end

# Post.not_comments.all.each do |post|
#   begin
#     RestClient.post(
#       File.join("#{UPLOAD_SCHEME}://#{net_id}:#{password}@#{HOST}", '/admin/news'),
#       {'news' => post.news_attributes, 'without_expire' => 'true', 'publish' => '1'},
#       :accept => :html
#     )
#   rescue RestClient::Found => e
#     uri = URI.parse(e.response.headers[:location])
#     post.update_attribute(:conductor_admin_path, uri.path)
#     log.info("Posted blog post #{post.blogger_id}")
#   rescue Exception => e
#     require 'ruby-debug'; debugger; true;
#   end
# end

FasterCSV.open(File.join(File.dirname(__FILE__), '../url.map.csv'), 'w+') do |csv|
  Post.not_comments.all.each do |post|
    csv << [post.from_url, post.to_url]
  end
end
