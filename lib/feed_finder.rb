require 'rubygems'
require 'rbrainz'
require 'hpricot'
require 'timeout'
require 'open-uri'
require 'htmlentities'
require 'feed-normalizer'

class FeedNormalizer::Entry
  attr_accessor :source
end

module FeedFinder

  def rbrainz_artist(artist_gid)
    query  = MusicBrainz::Webservice::Query.new
    artist_includes = MusicBrainz::Webservice::ArtistIncludes.new(
      :url_rels     => true
    )
    query.get_artist_by_id(artist_gid, artist_includes)
  end
  
  def get_feeds(mb_object)
    urls = filter_urls mb_object.get_relations(:target_type => MusicBrainz::Model::Relation::TO_URL)
    feeds = urls.map do |url|
      if (url.type =~ /Myspace$/)
        url.target.sub!(%r[http://(www.)?], 'http://blog.')
      end
      locate_links(url.target)
    end
    feeds.flatten.uniq
  end

  def get_stories(feeds)
    stories = []
    feeds.each do |url|
      begin
        feed = Timeout::timeout(10) { FeedNormalizer::FeedNormalizer.parse open(url) }
        feed.entries.each { |e| e.source = feed.title }
        stories.push(*feed.entries)
      rescue Timeout::Error
        puts "Timed out accessing #{url}"
      rescue SocketError => e
        puts "Server not found: #{url}"
      rescue OpenURI::HTTPError => e
        puts "404 not found: #{url}"
      end
    end
        
    coder = HTMLEntities.new
    stories.each do |story|
      story.title = coder.decode(story.title)      
    end

    stories.sort do |a,b| 
      if (a.last_updated.nil? or b.last_updated.nil?)
        b.urls.first <=> a.urls.first
      else
        b.last_updated <=> a.last_updated
      end
    end
  end
  
  private
    
  def filter_urls(urls)
    urls.find_all do |url| 
      (url.type =~ /OfficialHomepage$/ or url.type =~ /Blog$/ or url.type =~ /Fanpage$/ or url.type =~ /Myspace$/)
    end
  end
  
  def tidy_link(site, link)
    link = $1 if link =~ %r{^\[(.*)\]$}
    if (link =~ %r{^http://} )
      link
    else
      base = URI.parse(site)
      link_path, link_query = link.split('?')
      base_path = File.dirname(base.path)
      new_path = (base_path == '.') ? link_path : "#{base_path}/#{link_path}"
      new_path = '/' + new_path unless new_path =~ %r{^/}
      base.path, base.query = new_path, link_query
      base.to_s
    end
  end
  
  def locate_links(url)
    links = []
    begin
      doc = Timeout::timeout(10) { Hpricot(open(url)) }
      links << (doc/"//link[@rel='alternate']")
      links << (doc/"//a").find_all { |a| a.inner_html.downcase == 'rss' }
    rescue Timeout::Error
      puts "Timed out accessing: #{url}"
    rescue SocketError => e
      puts "Server not found: #{url}"
    rescue OpenURI::HTTPError => e
      puts "404 not found: #{url}"
    end
    links.flatten.map { |l| tidy_link(url, l[:href]) }    
  end

  def locate_feeds_on_page(site)
    doc = Hpricot(open(site.target))
  end
           
end

if __FILE__==$0
  include FeedFinder
  artist_gid = ARGV.first
  artist = rbrainz_artist(artist_gid)
  feeds = get_feeds(artist)
  stories = get_stories(feeds)
  pp stories
end
