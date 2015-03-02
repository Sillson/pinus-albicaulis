require './g5GC'
require 'highline/import'

path = File.expand_path(File.dirname(__FILE__))

say "Welcome to G5's Backdoor into GatherContent"

say "Hello there!"

choose do |menu|
  menu.prompt = "What would you like to download?  "

  menu.choice("Download Files by Page") { 

    dump_name = ask "Your files will be downloaded to #{path}, what would you like to name this folder?: "

    page_id = ask "Please enter the page id you'd like to download files from: "

    say "We will get right to downloading #{dump_name} for you. Please be patient."

    download_page_photos(page_id, path, dump_name)

    say "If you have any questions, please ask Stuart"


  }
  
  menu.choice("Download Files by Full Project") { 
    
    dump_name = ask "Your files will be downloaded to #{path}, what would you like to name this folder?: "

    project_id = ask "Please enter the project id you'd like to download: "

    say "We will get right to downloading #{dump_name} for you. Please be patient."

    to_be_downloaded = G5Api.new.project_grab(project_id)

    download_project_photos(to_be_downloaded, path, dump_name)

    say "If you have any questions, please ask Stuart"

  }

  menu.choice("Exit"){
    say "Peace Out"
    
    exit 
  }
end
