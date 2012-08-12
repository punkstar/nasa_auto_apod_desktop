#!/usr/bin/env ruby

require 'rss'
require 'open-uri'
require 'nokogiri'
require 'net/http'
require 'logger'
require 'uri'
require 'fileutils'

APOD_RSS_URL = 'http://apod.nasa.gov/apod.rss'
LOCAL_IMAGE_DIR = File.join ENV['HOME'], 'Pictures/APOD/'

$logger = Logger.new STDERR

def download_image(image_url)
    local_filename = File.join(LOCAL_IMAGE_DIR, File.basename(URI.parse(image_url).path))
    
    $logger.info "Saving #{image_url} to #{local_filename}"
    FileUtils.mkdir_p(File.dirname(local_filename))
    File.open(local_filename, 'wb') do |local_fh|
        open(image_url) do |remote_fh|
            local_fh.write remote_fh.read
        end
    end
    
    return local_filename
end

def set_desktop_image(image_path)
    $logger.info "Setting desktop to #{image_path}"
    `osascript -e 'tell application "Finder" to set desktop picture to {"#{image_path}"}'`
end

$logger.info "Fetching latest images from #{APOD_RSS_URL}"
rss = RSS::Parser.parse(open(APOD_RSS_URL), false)
if rss.items.length > 0
    apod_url = rss.items.first.link
    apod_doc = Nokogiri::HTML(open(apod_url))
    apod_doc.css('body a').each do |link|
        link_href = link[:href]
        if link_href =~ /\.((jpe?g)|(png)|gif)$/
            if link_href !~ /http?s:\/\//
                link_href = "http://apod.nasa.gov/#{link_href}"
            end
            $logger.info "Found image #{link_href}"
            local_image = download_image(link_href)
            set_desktop_image(local_image)
            $logger.info "Done"
            exit
        end
    end
else
    raise "Couldn't find feed items in rss feed"
end

