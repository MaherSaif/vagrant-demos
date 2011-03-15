require 'rubygems'
require 'rest_client'            
require 'json'    
require 'ap'
require 'tumblr'  
require 'rest-graph' 
require 'open-uri'    
require 'uri'
   
resturl = "http://wordpress.42foo.com:4567/api/"
author="admin"

content = ""
                                         
result =  JSON.parse(RestClient.post "#{resturl}get_nonce/", { :controller=>"posts", :method=>"create_post" }, :content_type => :json, :accept => :json)

ap result

  rest_hash = {
    :nonce => result["nonce"],
    :status => "publish",
    :title => "Der Title des Postings",
    :content => "<h2>Und das ist unser Posting</h2><p>und ein wenig text</p><p>und noch ein wenig text</p>",
    :categories => "Testposting",  
    :tags =>"ein,super,posting",
    :author => author,
    :attachment => File.new("photo.jpg", 'rb'),
  }

  post_result =  RestClient.post "#{resturl}create_post/", rest_hash, :content_type => :json, :accept => :json      
 ap JSON.parse(post_result) 
 
 Tumblr.blog = "it-eh"
 Tumblr::Post.all.each do |post|
   if post["type"] == "regular" 
     post_result =  RestClient.post "#{resturl}create_post/", {
       :nonce => result["nonce"],
       :status => "publish",
       :title => post["regular_title"],
       :categories => "tumblr",  
       :content => post["regular_body"]
     }, :content_type => :json, :accept => :json      
  end
end 

rg = RestGraph.new

class Tempfile  
  attr_accessor :original_filename#, :content_type; 
end

posts = rg.get("iTeh.Solutions/posts")
require 'net/http'

posts["data"].each do |post|
  content = ""
  title = ""  
  tempfile = nil 
  
  case post["type"]
  when "photo"
    content = post["message"]+"<img src='#{post["picture"]}'>" 
    title = post["message"]     

    tempfile = Tempfile.new("image")
    tempfile.binmode
    tempfile.original_filename = File.basename URI::parse(post["picture"]).path
    tempfile.write open( post["picture"],"rb" ).read
    tempfile.rewind
  when "status"
    content = post["message"] 
    title = post["message"]
  when "link"
    content = post["description"] 
    title = post["name"]
  end    
  
  rest_hash = {
    :nonce => result["nonce"],
    :status => "publish",
    :title => title,
    :content => content,
    :categories => "facebook",  
    :tags =>"ein,super,posting",
    :author => author,
  } 
  rest_hash[:attachment] = tempfile if tempfile#File.open("image.jpg","rb") 
  ap rest_hash
  RestClient.post "#{resturl}create_post/", rest_hash, :content_type => :json, :accept => :json  
  puts tempfile.path if  tempfile
  tempfile.delete  if tempfile
end  
     


