require 'rubygems'
require 'rack'
require 'camping'

require 'music_news.rb'
run Rack::Adapter::Camping.new( MusicNews )

