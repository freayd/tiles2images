require 'fileutils'
require 'net/http'
require 'uri'

zoom = 2
dir = 'osm'
url = 'https://a.tile.openstreetmap.org/{z}/{x}/{y}.png'

list = Magick::ImageList.new
extension = File.extname(url)
(2 ** zoom).times do |x|
  paths = (2 ** zoom).times.map do |y|
    path = File.join(__dir__, dir, zoom.to_s, x.to_s, "#{y}#{extension}")

    unless File.exist?(path)
      FileUtils.makedirs(File.dirname(path))
      uri = URI(url.sub('{z}', zoom.to_s).sub('{x}', x.to_s).sub('{y}', y.to_s))
      sleep 0.1
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.port == 443) do |http|
        begin
          File.open(path, 'wb') do |file|
            http.request_get(uri.request_uri) do |response|
              response.read_body do |segment|
                file.write(segment)
              end
            end
          end
        rescue Exception
          File.delete(path)
          raise
        end
      end
    end

    path
  end
  list << Magick::ImageList.new(*paths).append(true)
end
path = File.join(__dir__, dir, zoom.to_s)
image = list.append(false)
image.write("#{path}#{extension}") unless File.exists?("#{path}#{extension}")
