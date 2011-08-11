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

