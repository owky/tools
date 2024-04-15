require './google_api'
require 'yaml'

class PieniAutoUploader
  PHOTO_DIR = "/Volumes/Pieni/PHOTO/"
  VIDEO_DIR = "/Volumes/Pieni/VIDEO/"
  CONFIG_FILE = "config.yml"

  def initialize
    upload_all PHOTO_DIR
    upload_all VIDEO_DIR
  end

  def config
    @config ||= {
      client_id: "",
      client_secret: "",
      refresh_token: "",
      album_id: "",
    }.merge(load_config)
  end

  def access_token
    @access_token ||= GooglePhotos::Auth.access_token(
      config[:client_id], config[:client_secret], config[:refresh_token])
  end

  def upload_all(dir)
    Dir.foreach(dir) do |file|
      next unless file =~ /^[^\.]+\.(jpg|avi)$/
      puts dir + file
      upload(dir + file)
      File.delete(dir + file)
    end
  end

  def upload(file)
    upload_token = GooglePhotos::Media.upload(access_token, File.open(file, "r+b")).body
    GooglePhotos::Media.create(access_token, upload_token, config[:album_id])
  end

  def load_config
    YAML.load(File.open(CONFIG_FILE).read).map do |k,v|
      [k.to_sym, v]
    end.to_h
  end
end

begin
  File.delete("error") if File.exist?("error")
  PieniAutoUploader.new
rescue
  File.open("error", "w") do |f|
    f.puts $!
  end
end
