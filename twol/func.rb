# Functions used in twitter wordlist generator app.

def banner()
    p "+-------------------------------------------------------------------------+"
    p "| twol is a simple code to generate a wordlist from a given user's tweets |"
    p "| Developed by Symturk Ltd. (http://www.symturk.com)                      |"
    p "+-------------------------------------------------------------------------+"
end



def usage()
    print("
      Available options
      -h, --help        displays this help info. 
      -u, --user        twitter user to search
      -k, --keyword     keyword to search
      -o, --outfile     output file to write results.  
")
end



def checkRateLimit()
    begin
        while Twitter.rate_limit_status.remaining_hits == 0
            reset_time = Twitter.rate_limit_status.reset_time_in_seconds
            now = Time.now.to_i 
            sleep_time = reset_time - now 
            p "No rate limit.. Sleep for: " + sleep_time.to_s + "secs."
            p "Estimated time to continue: " + Twitter.rate_limit_status.reset_time.to_s
            sleep(sleep_time)
        end 
  
    rescue Faraday::Error::ConnectionFailed
        #p "Connection Error.. will try in 5 secs."
        sleep(5)
        retry
    rescue Errno::ETIMEDOUT
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::ServiceUnavailable
        #p "Twitter over capacity.. will try in 10 secs."
        sleep(10)
        retry
    rescue Faraday::Error::TimeoutError
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::BadGateway
        #p "Twitter is down.. will try in 10 secs."
        sleep(10)
        retry
    rescue Zlib::GzipFile::Error
        #p "not in gzip format - HTTP Error.. will try in 5 secs."
        sleep(5)
        retry
    end

    return true
end



def getRateLimit()
    begin
        limit = Twitter.rate_limit_status.remaining_hits 
    rescue Faraday::Error::ConnectionFailed
        sleep(5)
        retry
    rescue Errno::ETIMEDOUT
        sleep(5)
        retry
    rescue Twitter::Error::ServiceUnavailable
        sleep(10)
        retry
    rescue Faraday::Error::TimeoutError
        sleep(5)
        retry
    rescue Twitter::Error::BadGateway
        sleep(10)
        retry
    rescue Zlib::GzipFile::Error
        sleep(5)
        retry
    end

    return limit
end



def getHashTags(tweets)
    #extract hashtags of a given tweet
    p "--> Extracting hash tags"
    hashtags = []
    tweets.each do |tweet|
        hashtag = tweet.text.scan(/#[[:alpha:]]+|#[\d\+-]+\d+/).collect{|x| x[1..-1]}
        unless (hashtag.nil? || hashtag.empty?)
            hashtags << hashtag
        end
    end

    return hashtags.flatten.uniq
end


def searchHashTag(hashtag)
    # search given hashtag
    p "--> Searching Hashtag:" + hashtag
    tweets = []
    if checkRateLimit == true
        result=Twitter.search("##{hashtag} -rt", :rpp => 500)
    end
    result.each do |tweet|
        tweets << tweet
    end

    return tweets
end


def getTweets(name)
    p "-->Getting Tweets for:" + name
    #Get last 200 tweets of a user
    tweets = []
    begin
#  (1..16).each do |page| 
    if checkRateLimit() == true
        Twitter.user_timeline(name, :page => 1, :count => 200).each do |tweet|
            $stdout.sync = true
            tweets << tweet
        end
        p " ...done"
    end
#  end

    rescue Faraday::Error::ConnectionFailed
        #p "Connection Error.. will try in 5 secs."
        sleep(5)
        retry
    rescue Errno::ETIMEDOUT
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::ServiceUnavailable
        #p "Twitter over capacity.. will try in 10 secs."
        sleep(10)
        retry
    rescue Faraday::Error::TimeoutError
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::BadGateway
        #p "Twitter is down.. will try in 10 secs."
        sleep(10)
        retry
    rescue Zlib::GzipFile::Error
        #p "not in gzip format - HTTP Error.. will try in 5 secs."
        sleep(5)
        retry
    end

    return tweets
end


def parseTweets(tweets)
#parse given tweet message and add to wordlist
    p "---> Parsing Tweets.."
    wordlist = []
    urllist = []
    link_regex = /(http:\S+|https:\S+)/
    nonprint_regex = /[^[:alnum:]|^[:space:]]/
    tweets.each do |tweet|
        url = tweet.text.scan(link_regex)
        tweet_content = tweet.text.gsub(/[^[:alnum:]|^[:punct:]|^[:space:]]/,'')

        unless (url.nil? || url.empty?)
             tweet_content = tweet.text.gsub(link_regex,'')
        end

        wordlist << tweet_content.split(/ /).delete_if {|x| x == "" }
    end

    return wordlist
end



def getFriends(name)
# get friends of a given user
    p "--> Getting Friend List for:" + name
    begin
        temp = Hash.new
        friends_info = Array.new
        if checkRateLimit == true
            friends = Twitter.friend_ids(name)
        end

        friends_info = Array.new(friends['ids'].size, 0)

        i = 0

        friends.ids.each do |fid|
            if checkRateLimit == true
                $stdout.sync = true
                f = Twitter.user(fid)
                temp['screen_name'] = f.screen_name
                temp['name'] = f.name
                temp['description'] = f.description
                temp['is_protected'] = f.protected

                friends_info[i] = Hash[temp]
                print "."
            end
            i += 1
        end
        p "  done"

    rescue Faraday::Error::ConnectionFailed
        #p "Connection Error.. will try in 5 secs."
        sleep(5)
        retry
    rescue Errno::ETIMEDOUT
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::ServiceUnavailable
        #p "Twitter over capacity.. will try in 10 secs."
        sleep(10)
        retry
    rescue Faraday::Error::TimeoutError
        #p "Connection Timeout.. will try in 5 secs."
        sleep(5)
        retry
    rescue Twitter::Error::BadGateway
        #p "Twitter is down.. will try in 10 secs."
        sleep(10)
        retry
    rescue Zlib::GzipFile::Error
        #p "not in gzip format - HTTP Error.. will try in 5 secs."
        sleep(5)
        retry
    end

    return friends_info
end



def reviseWordList(list)
    p "---> Processing WordList.."
    word_list  = Array.new
    list.each do |word|
        word = word.gsub(/[^[:alnum:]|^[:punct:]]/,'')
        # word = word.gsub(/[\x80-\xff]/, '')
        word_list << word

        coder = HTMLEntities.new
        # decode html special chars
        decoded_word = coder.decode(word)

        if decoded_word != word
            word_list << decoded_word
        end

        # extrach alphanum chars only
        stripped_word = decoded_word.gsub(/[^[:alnum:]]/,'')

        if stripped_word != decoded_word
            word_list << stripped_word
        end

    end

  return word_list
end

