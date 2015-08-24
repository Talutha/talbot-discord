class BotConfig

  def initialize
    @config = YAML.load_file "lib/talbot/config.yaml"
  end

  def email
    @config["email"]
  end

  def password
    @config["password"]
  end

  def host
    @config["host"]
  end

  def dbname
    @config["dbname"]
  end

  def dbuser
    @config["dbuser"]
  end

  def dbpassword
    @config["dbpassword"]
  end

  def stream_announce
    @config["stream_announce"]
  end

end
