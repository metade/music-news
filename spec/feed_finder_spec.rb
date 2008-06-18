require File.join(File.dirname(__FILE__), '..', 'lib', 'feed_finder')

include FeedFinder

describe FeedFinder do
  
  describe "tidying links" do
    it "should convert a relative link to an absolute one" do
      link = tidy_link('http://www.pleasureunit.com/coldplay/index.php', 'news.xml')
      link.should == 'http://www.pleasureunit.com/coldplay/news.xml'
    end

    it "should leave an absolute link alone" do
      link = tidy_link('http://www.pleasureunit.com/coldplay/index.php', 'http://www.pleasureunit.com/coldplay/news.xml')
      link.should == 'http://www.pleasureunit.com/coldplay/news.xml'
    end

    it "should cope with a url with no path" do
      link = tidy_link('http://murmurs.com/', '/frontpage/feed?s=41beb4aa20e453c218749b7768f37f2d')
      link.should == 'http://murmurs.com///frontpage/feed?s=41beb4aa20e453c218749b7768f37f2d'
    end

    it "should cope with a url with no trailing slash and with no path" do
      link = tidy_link('http://www.themusic.co.uk', 'rss_news.php')
      link.should == 'http://www.themusic.co.uk/rss_news.php'
    end

    it "should clean up links with [] (david bowie)" do
      link = tidy_link('http://www.bowiewonderworld.com', '[http://www.bowiewonderworld.com/bowiewonderworld.xml]')
      link.should == 'http://www.bowiewonderworld.com/bowiewonderworld.xml'      
    end
  end
  
  describe "finding links" do
     it "should work out a relative link" do
       feeds = locate_links('http://www.pleasureunit.com/coldplay/index.php')
       feeds.should == ['http://www.pleasureunit.com/coldplay/news.xml']
     end
  
     it "should find a myspace blog link" do
       feeds = locate_links('http://blog.myspace.com/coldplay')
       feeds.should == ['http://blog.myspace.com/blog/rss.cfm?friendID=2951183']
     end  
   end
   
  describe "for Coldplay" do
    before :all do
      @artist = rbrainz_artist('cc197bad-dc9c-440d-a5b5-d52ba2e14234')
      @feeds = get_feeds(@artist)
    end
   
    it "should get some feeds" do
      @feeds.should_not be_empty
    end
  
    it "should include the myspace feed" do
      @feeds.should be_include('http://blog.myspace.com/blog/rss.cfm?friendID=2951183')
    end
  
    it "should include the coldplay fanpage feed" do
      @feeds.should be_include('http://www.pleasureunit.com/coldplay/news.xml')
    end
  end
  
  describe "for The Zutons" do
    before :all do
      @artist = rbrainz_artist('6290b769-173d-49d1-990e-660a4e333877')
      @feeds = get_feeds(@artist)
      @stories = get_stories(@feeds)
    end
    
    it "should get some feeds" do
      @feeds.should_not be_empty
    end
    
    it "should get some stories" do
      @stories.should_not be_empty
    end
  end
    
end
