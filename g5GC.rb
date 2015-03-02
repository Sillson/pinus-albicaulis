require 'base64'
require 'dotenv'
require 'fileutils'
require 'hashie/mash'
require 'httparty'
require 'json'
require 'open-uri'

Dotenv.load

class GatherContentApi
  include HTTParty
  format :json
  # debug_output $stdout

  def initialize(subdomain, u, p)
    self.class.base_uri('https://' + subdomain + '.gathercontent.com/api/0.4')
    @auth = {:username => u, :password => p}
  end

  def method_missing(method, *args, &block)
    options = {:body => {'id' => args[0]}, :digest_auth => @auth}
    self.class.post('/' + method.to_s, options)
  end

end

class G5Api

  def initialize
    @api = GatherContentApi.new(ENV["ORGANIZATION"], ENV["API_KEY"], 'x')
  end

  def project_grab(id)
    mash = Hashie::Mash.new(@api.get_pages_by_project(id)).drop(1).first[1]
    @output = sorted_hash(mash)
  end

  def file_grab(id)
    @output = Hashie::Mash.new(@api.get_files_by_page(id)).drop(1).first[1]
  end

end

# public methods

def sorted_hash(returned_hash)
  by_id = returned_hash.group_by(&:id)
  page_hash = returned_hash.group_by { |page| by_id[page.parent_id]}
end

def download_page_photos(page, path, dump_name)
  puts 'Downloading your photos Sir/Mam'
  list = []
  stamp = Time.now
  image = G5Api.new.file_grab(page)
  image.class == Array ? list.push(image) : abort('There are no photos on this page!')
  list.flatten.each do |i|
    FileUtils::mkdir_p "#{path}/#{dump_name}_#{stamp}/"
    open("#{path}/#{dump_name}_#{stamp}/#{i.original_filename}", 'wb') do |file|
      file << open("https://gathercontent.s3.amazonaws.com/#{i.filename}").read
    end
  end
end

def download_project_photos(sorted_hash, path, dump_name)
  list = []
  stamp = Time.now
  sorted_hash.each do |key, value|
    if key.nil?
      value.each do |write|
        puts "Writing #{write.name}"
        if Dir["#{path}/#{dump_name}_#{stamp}/#{write.name}"].empty?
          FileUtils::mkdir_p "#{path}/#{dump_name}_#{stamp}/#{write.name}"
        end
        image = G5Api.new.file_grab(write.id)
        while image.empty? == false do
          begin
            list.push(image.shift)
          rescue
            puts "There are no files on this page!"
            image.clear
          end
        end
        list.flatten.each do |i|
          if i.page_id == write.id
            open("#{path}/#{dump_name}_#{stamp}/#{write.name}/#{i.original_filename}", 'wb') do |file|
              file << open("https://gathercontent.s3.amazonaws.com/#{i.filename}").read
            end
          end
        end
      end
    end
    if key != nil
      value.each do |write|
        puts "Writing #{write.name}"
        if Dir["#{path}/#{dump_name}_#{stamp}/#{key[0]}/#{write.name}"].empty?
          FileUtils::mkdir_p "#{path}/#{dump_name}_#{stamp}/#{key[0].name}/#{write.name}"
        end
        image = G5Api.new.file_grab(write.id)
        while image.empty? == false do
          begin
            list.push(image.shift)
          rescue
            puts "There are no files on this page!"
            image.clear
          end
        end
        list.flatten.each do |i|
          if i.page_id == write.id
            open("#{path}/#{dump_name}_#{stamp}/#{key[0].name}/#{write.name}/#{i.original_filename}", 'wb') do |file|
              file << open("https://gathercontent.s3.amazonaws.com/#{i.filename}").read
            end
          end
        end
      end
    end   
  end
end





