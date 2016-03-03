$LOAD_PATH << File.dirname(__FILE__)

require 'mongoid'
require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'

require 'sinatra/base'
require 'resque'

require 'helpers/response_helper'
require 'middleware/socket'
require 'model/aggregate.rb'
require 'gorilla'
require 'daemon'
