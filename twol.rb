#!/usr/bin/ruby

require 'rubygems'
require 'twitter'
require 'htmlentities'
require 'getoptlong'

require_relative 'twol/func'

user, keyword, outfile = nil
friend_list = Hash.new


opts = GetoptLong.new(
           [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
           [ '--user', '-u', GetoptLong::OPTIONAL_ARGUMENT ],
#           [ '--keyword', '-k', GetoptLong::OPTIONAL_ARGUMENT ],
           [ '--outfile', '-o', GetoptLong::OPTIONAL_ARGUMENT ],
       )

opts.each do |opt, arg|
    case opt
        when '--help'
            banner()
            usage()
            exit
        when '--outfile'
            outfile = arg
        when '--user'
            user = arg
        when '--keyword'
            keyword = arg
    end
end


banner()

if (user.nil? || outfile.nil?)
    usage()
    exit
end


p "-> Generating wordlist for:" + user
p "-> Results will be written in file:" + outfile

user_tweets = getTweets(user)

if user_tweets.size > 0
    user_hashtags = getHashTags(user_tweets)
    word_list = parseTweets(user_tweets)
end


if user_hashtags.size > 0
    user_hashtags.each do |hashtag|
        p hashtag
        hashtagtweets = searchHashTag(hashtag)
        if hashtagtweets.size > 0
            word_list += parseTweets(hashtagtweets)
        end
    end
end

user_friends = getFriends(user)

user_friends.each do |f|
# Only iterate if we can see their tweets
    if (f['is_protected'].to_s != "true")
        user_tweets = getTweets(f['screen_name'])
        if user_tweets.size > 0
            word_list += parseTweets(user_tweets)
        end
    end
end

word_list = reviseWordList(word_list.flatten.sort.uniq)


File.open("#{outfile}", 'w') do |f|  
    f.puts word_list.flatten.sort.uniq
end  

p "-> Completed..."
