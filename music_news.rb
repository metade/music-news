require 'lib/feed_finder.rb'

Camping.goes :MusicNews

module MusicNews
  include FeedFinder
end

module MusicNews::Controllers
  class Index < R '/'
    def get
      render :index 
    end
  end

  class Artists < R '/artists/?'
    def get
      @content = File.read('files/artists.html')
      render :artists      
    end
  end
  
  class Artist < R '/artists/(.+)'
    def get(gid)
      @artist = rbrainz_artist(gid)
      @feeds = get_feeds(@artist)
      @stories = get_stories(@feeds)
      render :artist
    end
  end
end

module MusicNews::Views
  def layout
    html do
      title { 'Music News' }
      body { self << yield }
    end
  end
  
  def index
  end

  def artists
    text @content
  end
  
  def artist
    table do
      tr do
        th { 'Date' }
        th { 'Source' }
        th { 'Post' }
      end
      @stories.each do |story|
        tr do
          td { story.last_updated }
          td { story.source }
          td { a story.title, :href => story.urls.first }
        end
      end
    end
  end
end
