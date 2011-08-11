#!/usr/bin/env ruby
require 'hpricot'
require 'yaml'
require 'logger'
require 'fileutils'
require 'rest_client'
require 'highline'
require "highline/import"

require File.join(File.dirname(__FILE__), 'database')

UPLOAD_SCHEME = 'http'
HOST = 'localhost:3000'

def net_id
  @net_id ||= ask(%(<%= color("Net ID: ", :black, :on_yellow)%>))
end

def password
  @password ||= ask(%(<%= color("Password: ", :black, :on_yellow)%>)) { |q| q.echo = "*" }
end

Post.all.each do |post|
  content = Hpricot(post.content)
  (content/'img').each do |img_tag|
    source_url = img_tag.get_attribute('src')
    # Remove the google tracking code.  No sense processing it.
    if source_url !~ /#{Regexp.escape("https://blogger.googleusercontent.com/tracker/")}/
      post.assets.create!(:source_url => source_url)
    end
  end
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

Asset.all.each do |asset|
  dirname = File.join(File.dirname(__FILE__), "../tmp/assets/#{asset[:id]}/")
  FileUtils.mkdir_p(dirname)
  temp_filename = File.join(dirname, "#{File.basename(asset.source_url.to_s)}")
  with_rest_timeout_retry(3) do
    response = RestClient.get(asset.source_url)
    File.open(temp_filename, 'w+') do |file|
      file.puts response.body
    end
  end
  asset.update_attribute(:local_filename, temp_filename)
end

# Upload asset
Asset.all.each do |asset|
  with_rest_timeout_retry(3) do
    begin
      RestClient.post("#{UPLOAD_SCHEME}://#{net_id}:#{password}@#{File.join(HOST, "/admin/assets")}",
      {"asset" => { "file" => File.new(asset.local_filename), 'tag' => 'imported' }, 'without_expire' => 'true'}
      )
    rescue RestClient::Found => e
      uri = URI.parse(e.response.headers[:location])
      asset_id = uri.path.sub(/^\/admin\/assets\/(\d+)(\/.*)?/, '\1')
      asset.update_attribute(:conductor_asset_id, asset_id)
    end
  end
end
