#!/usr/bin/ruby
# encoding: utf-8

# Make sure you have these gems installed
require 'rubygems'
require 'thread'
require 'csv'
require 'open-uri'

require 'parseconfig'
require 'twitter'
require 'marky_markov'
require 'htmlentities'
require 'ensure/encoding'

# Create a new Twitter account that you'd like to have your auto-tweets posted to
# Go to dev.twitter.com, create a new application with Read+Write permissions
# Create an access token + secret for the account and copy that and the consumer key and secrets into config.txt
config = ParseConfig.new('config.txt')
ACCESS_TOKEN =  config['ACCESS_TOKEN'] || abort('Can\'t post to Twitter without ACCESS_TOKEN in config.txt')
ACCESS_TOKEN_SECRET =  config['ACCESS_TOKEN_SECRET'] || abort('Can\'t post to Twitter without ACCESS_TOKEN_SECRET in config.txt')
CONSUMER_KEY =  config['CONSUMER_KEY'] || abort('Can\'t post to Twitter without CONSUMER_KEY in config.txt')
CONSUMER_SECRET =  config['CONSUMER_SECRET'] || abort('Can\'t post to Twitter without CONSUMER_SECRET in config.txt')

# These can be overridden in config.txt but have defaults; be sure to use double-quotes if PATH_TO_TWEETS_CSV is a URI!
PATH_TO_TWEETS_CSV   = config['PATH_TO_TWEETS_CSV'] || 'tweets.csv'
PATH_TO_TWEETS_CLEAN = config['PATH_TO_TWEETS_CLEAN'] || 'markov_dict.txt'

### -----------------------------------------------------------------------------------------------------

# We need a source of tweets in PATH_TO_TWEETS_CSV
# Go to Twitter.com -> Settings -> Download Archive to get a CSV file
# Any other CSV file with the tweets in the sixth column will also work.
# You can also supply a URI, eg "http://somedomain/somefile.csv"
file_contents = open(PATH_TO_TWEETS_CSV, "Accept-Charset" => "UTF-8") { |f| f.read }

# If it's retrieved from a URI, Ruby somehow thinks it's encoded as ASCII-8BIT. It shouldn't...
file_contents = file_contents.ensure_encoding('UTF-8', :external_encoding => :sniff, :invalid_characters => :transcode)

# Be extra paranoid about encoding...
csv_text = CSV.parse(file_contents.encode!("UTF-8", {invalid: :replace}))

# We'll want to re-encode HTML entities, otherwise they look dumb
coder = HTMLEntities.new

# Create a new clean file of text that acts as the seed for your Markov chains
File.open(PATH_TO_TWEETS_CLEAN, 'w') do |file|
  csv_text.reverse.each do |row|

    # Strip links and new lines
    tweet_text = row[5].gsub(/(?:f|ht)tps?:\/[^\s]+/, '').gsub(/\n/,' ')
 
 	# Strip #sorrynotsorry in any capitalization
    tweet_text = tweet_text.gsub(/#sorrynotsorry/i, '')

    # Strip leading RT's
    tweet_text = tweet_text.gsub(/^RT\s+/, '')

    # Re-encode any HTML entities
    tweet_text = coder.decode(tweet_text)

    # Save the text
    file.write("#{tweet_text}\n")

  end
end
  
# Run when you want to generate a new Markov tweet
markov = MarkyMarkov::TemporaryDictionary.new
markov.parse_file PATH_TO_TWEETS_CLEAN
tweet_text = markov.generate_n_sentences(2).split(/\#\</).first.chomp.chop
    
# Connect to your Twitter account
# Twitter.configure do |config|
#   config.consumer_key    = CONSUMER_KEY
#   config.consumer_secret = CONSUMER_SECRET
# end
# twitter_client = Twitter::Client.new(:oauth_token => ACCESS_TOKEN,
#                               :oauth_token_secret => ACCESS_TOKEN_SECRET)
# p "#{Time.now}: #{tweet_text}"
# twitter_client.update(tweet_text)

puts(tweet_text)
