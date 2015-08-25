require 'sequel'
require_relative 'config'

class DatabaseCalls

  def initialize
    @config = BotConfig.new
    connect_to_database
    load_db_extensions
    create_tables
    grab_tables
  end

  def insert_new_video(username, userid, url)
    @video_share.insert(:username => username, :userid => userid, :url => url,
                        :upvotes => 0, :downvotes => 0, :total => 0,
                        :timestamp => Time.now)
  end

  def register_vote(userid, videoid, vote)
    if vote == "upvote"
      upvote(userid, videoid)
    elsif vote == "downvote"
      downvote(userid, videoid)
    end
    add_to_voted(userid, videoid)
    latest_video_id
  end

  def voted_list(videoid)
    list = @video_share.where[:id => videoid][:voted]
    list = [] unless list != nil
    return list
  end

  def last_video_id
    id = latest_video_id
    return id
  end

  def get_scores(videoid)
    upvotes = @video_share.where[:id => videoid][:upvotes]
    downvotes = @video_share.where[:id => videoid][:downvotes]
    total = @video_share.where[:id => videoid][:total]
    return upvotes, downvotes, total
  end

  def get_video(videoid)
    url = @video_share.where[:id => videoid][:url]
    userid = @video_share.where[:id => videoid][:userid]
    timestamp = @video_share.where[:id => videoid][:timestamp]
    return url, userid, timestamp
  end

  def get_top_video
    get_id = @DB[:discord_video_share].reverse_order(:total).limit(1)
    id = get_id.first[:id]
    return id
  end

  def get_bottom_video
    get_id = @DB[:discord_video_share].order(:total).limit(1)
    id = get_id.first[:id]
    return id
  end

private

  def connect_to_database
    user = @config.dbuser
    pass = @config.dbpassword
    host = @config.host
    dbname = @config.dbname
    @DB = Sequel.connect("postgres://#{user}:#{pass}@#{host}/#{dbname}")
  end

  # Check the database and make sure the tables required exists
  def create_tables
    @DB.run(" CREATE TABLE IF NOT EXISTS discord_video_share(
                            id serial PRIMARY KEY NOT NULL,
                            url text NOT NULL,
                            username text NOT NULL,
                            userid bigint NOT NULL,
                            upvotes int NOT NULL,
                            downvotes int NOT NULL,
                            total int NOT NULL,
                            voted bigint[],
                            timestamp timestamp NOT NULL ); ")
  end

  def grab_tables
    @video_share = @DB[:discord_video_share]
  end

  def load_db_extensions
    @DB.extension :pg_array
  end

  def upvote(userid, videoid)
    @video_share.where(:id => videoid).update(:upvotes => Sequel.expr(1) + :upvotes)
    @video_share.where(:id => videoid).update(:total => Sequel.expr(1) + :upvotes)
  end

  def downvote(userid, videoid)
    @video_share.where(:id => videoid).update(:downvotes => Sequel.expr(1) + :downvotes)
    @video_share.where(:id => videoid).update(:total => Sequel.expr(-1) + :upvotes)
  end

  def add_to_voted(userid, videoid)
    voted_list = @video_share.where[:id => videoid][:voted]
    voted_list = [] unless voted_list != nil
    puts "Voted List = #{voted_list}"
    voted_list << userid
    @video_share.where(:id => videoid).update(:voted => Sequel.pg_array(voted_list))
  end

  def latest_video_id
    get_id = @DB[:discord_video_share].reverse_order(:id).limit(1)
    id = get_id.first[:id]
    return id
  end

end
