require 'sequel'
require_relative 'config'

class DatabaseCalls

  def initialize
    @config = BotConfig.new
    connect_to_database
    create_tables
    grab_tables
  end

  def insert_new_video(username, userid, url)
    @video_share.insert(:username => username, :userid => userid, :url => url,
                        :upvotes => 0, :downvotes => 0, :timestamp => Time.now)
  end

private

  def connect_to_database
    user = @config.dbuser
    pass = @config.dbpassword
    host = @config.dbhost
    dbname = @config.dbname
    @DB = Sequel.connect("postgres://#{user}:#{pass}@#{host}/#{dbname}")
  end

  # Check the database and make sure the tables required exists
  def create_tables
    @DB.run(" CREATE TABLE IF NOT EXISTS discord_video_share(
                            id int PRIMARY KEY UNIQUE NOT NULL,
                            url text NOT NULL,
                            username text NOT NULL,
                            userid int NOT NULL,
                            upvotes int NOT NULL,
                            downvotes int NOT NULL,
                            timestamp timestamp NOT NULL ); ")
  end

  def grab_tables
    @video_share = @DB[:discord_video_share]
  end

end
