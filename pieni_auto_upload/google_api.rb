require 'net/http'
require 'json'

class GooglePhotos
  class Auth
    def self.access_token(client_id, client_secret, refresh_token)
      uri = ::URI.parse('https://www.googleapis.com/oauth2/v4/token')
      params = {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: "refresh_token",
        refresh_token: refresh_token
      }
      req = ::Net::HTTP::Post.new(uri)
      req.set_form_data(params)

      res = ::Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(req)
      end

      JSON.parse(res.body)["access_token"]
    end
  end

  class Media
    MIME_TYPE = {'jpg' => 'image/jpeg', 'avi' => 'video/x-msvideo'}

    def self.upload(access_token, media)
      uri = ::URI.parse('https://photoslibrary.googleapis.com/v1/uploads')
      req = ::Net::HTTP::Post.new(uri)
      req['Authorization'] = "Bearer #{access_token}"
      req['Content-Type'] = 'application/octet-stream'
      req['X-Goog-Upload-Content-Type'] = MIME_TYPE[media.path.split('.').last]
      req['X-Goog-Upload-File-Name'] = media.path.split('/').last
      req['X-Goog-Upload-Protocol'] = 'raw'
      req.body = media.read

      res = ::Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
    end

    def self.create(access_token, upload_token, album_id)
      uri = ::URI.parse('https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate')
      req = ::Net::HTTP::Post.new(uri)
      req['Authorization'] = "Bearer #{access_token}"
      req['Content-Type'] = 'application/json'
      req.body = {
        albumId: album_id,
        newMediaItems: [
          {
            simpleMediaItem: {
              uploadToken: upload_token
            }
          }
        ]
      }.to_json

      res = ::Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
    end
  end
end
