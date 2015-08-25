require 'discordrb'
require 'json'
require 'open-uri'
require 'yaml'
require_relative './talbot/config'
require_relative './talbot/database'

@config = BotConfig.new
@bot = Discordrb::Bot.new @config.email, @config.password

@bot.message(with_text: "Ping!") do |event|
  puts "#{event.channel.id}"
  event.respond "Pong!"
end

@bot.message(in: "#video-share", from: not!("TalBotExtreme")) do |event|
  puts "-----[Video Share Message Received!] \nevent.author: #{event.author.username}\nevent.channel: #{event.channel.name}\nevent.content: #{event.content}\nevent.timestamp: #{event.timestamp}"
  author = "#{event.author.username}"
  userid = event.author.id
  message = "#{event.content}"
  timestamp = Time.now
  channel_id = event.channel.id
  share_video = VideoShare.new(author, message, timestamp, channel_id, userid)
  if share_video.require_response
    event.respond "#{share_video.response_message}"
  end
end

@bot.ready do |event|
  check_if_online_timer
end

def check_if_online_timer
  talutha = StreamStatus.new("talutha")
  hyperkind = StreamStatus.new("hyperkind")
  leavaris = StreamStatus.new("leavaris")
  bwana = StreamStatus.new("bwana")
  mello = StreamStatus.new("melloace")
  check_for = [talutha, hyperkind, leavaris, bwana, mello]
  Thread.new do
    while true
      check_for.each do |checking|
        if checking.online != false
          if checking.already_announced == false
            announce_online(checking)
          end
        else
          # Stream is offline!
        end
      end
      sleep(60)
    end
  end
end

def announce_online(checking)
  # Send a message to any channel @bot.send_message(room_id, "message")
  @bot.send_message(@config.stream_announce, "**#{checking.display_name}** has just started streaming! \n \n *__#{checking.game_name}__* \n #{checking.stream_title} \n \n Watch them right now at http://www.twitch.tv/#{checking.stream_name}")
  checking.already_announced = true
end

class StreamStatus

  attr_reader :stream_name, :stream_online, :game_name, :stream_title, :display_name
  attr_accessor :already_announced

  def initialize(name)
    @already_announced = false
    @stream_online = false
    @stream_name = name
    puts "----[Stream_status] Initialized #{@stream_name}"
  end

  def online
    parse = JSON.parse(open("https://api.twitch.tv/kraken/streams/#{@stream_name}").read)
    if parse["stream"] != nil
      @stream_online = true
      parse_the_parse(parse)
    else
      @stream_online = false
      @already_announced = false
    end
  end

private

  def parse_the_parse(parse)
    @game_name = parse["stream"]["game"]
    @stream_title = parse["stream"]["channel"]["status"]
    @display_name = parse["stream"]["channel"]["display_name"]
  end

end

class VideoShare

  attr_reader :require_response, :response_id, :response_message

  def initialize(author, message, timestamp, channelid, userid)
    @DB = DatabaseCalls.new
    @require_response = false
    parse_message(author, message, timestamp, channelid, userid)
  end

  def send_message(id, message)
    @require_response = true
    @response_id = id
    @response_message = message
  end

private

  def parse_message(author, message, timestamp, channelid, userid)
    if (message =~ URI::regexp) != nil
      # message contains a URL
      url = URI.extract(message)
      url_split = URI.split(url[0])
      # check to see if the URL is YouTube
      if url_split[2].downcase == "www.youtube.com"
        # Add video to Database
        @DB.insert_new_video(author, userid, url[0])
        # Send message explaining everything
        send_message(channelid, "I have added #{url} to the database!")
      end
    end
  end

end

@bot.run
