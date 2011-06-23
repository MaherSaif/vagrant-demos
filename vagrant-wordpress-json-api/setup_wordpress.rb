require "rubygems"
require "mechanize"

a = Mechanize.new
a.get('http://wordpress.smackaho.st:4567/wp-admin/install.php') do |page|
  step_2 = page.form_with(:action => 'install.php?step=2') do |f|
    f.weblog_title  = "Test Blog"
    f.user_name         = "admin"
    f.admin_password = "adminadmin"  
    f.admin_password2 = "adminadmin" 
    f.admin_email = "admin@wordpress.org" 
  end.click_button
end

module Wordpress
  #from https://gist.github.com/572383
  # A proof of concept class, displaying how to manage a WP blog through ruby
  class Blog
    attr_accessor :agent, :blog_uri, :username, :password, :logged_in
    def initialize blog_uri, username, password
      @username = username
      @password = password
      @blog_uri = blog_uri.gsub(/\/$/,"") # remove last slash if given
      @agent = Mechanize.new
      @current_page = @agent.get(blog_uri) # Will throw errors if page does not exist, or if blog_uri is invalid
      @logged_in = false
    end
    
    def logged_in?; @logged_in; end
    
    def enable_remote_blogging
      login!
      page = agent.page.link_with(:text => 'Writing').click
      form = page.forms.first
      form.checkbox_with(:name => 'enable_app').check
      page = agent.submit(form, form.buttons.first)
    end 
    
    def enable_permalinks
      login!
      page = agent.page.link_with(:text => 'Permalinks').click
      form = page.forms.first
      form.radiobuttons_with(:name => 'selection')[2].check
      page = agent.submit(form, form.buttons.first)
    end
    
    def enable_plugin(name)
      login!
      page = agent.page.link_with(:text => 'Plugins').click
      plugin = page.link_with(:href => /action=activate.*#{name}/)
      (plugin) ? plugin.click : "already enabled"
    end
    
    def enable_theme(name)
      login!
      page = agent.page.link_with(:text => 'Themes').click
      plugin = page.link_with(:href => /action=activate.*template=#{name}/)
      (plugin) ? plugin.click : "already enabled"
    end
    
    def enable_json_api
      login!
      page = agent.page.link_with(:href => /page=json-api/).click
      option = page.link_with(:href => /action=activate.*controller=posts/)
      (option) ? option.click : "already activated" 
      option = page.link_with(:href => /action=activate.*controller=core/)
      (option) ? option.click : "already activated"
    end   
    
    def custom_excerpt
      login!
      page = agent.page.link_with(:href => /options-advancedexcerpt/).click 
      form = page.forms.first                       
      form.checkbox_with(:value => 'img').uncheck 
      form.checkbox_with(:value => 'a').uncheck  
      form.advancedexcerpt_ellipsis="..."
      form.checkbox_with(:name => 'advancedexcerpt_add_link').check  
      form.action = "/wp-admin/options-general.php?page=options-advancedexcerpt" 
      page = agent.submit(form, form.button_with(:name => /ubmit/))

    end
    
    def login!
      unless logged_in?
        page = agent.get(login_uri)
        form = page.form('loginform')
        form.log = username
        form.pwd = password
        agent.submit(form, form.buttons.first)
        logged_in = true
      end
    end
    
    def login_uri; "#{blog_uri}/wp-login.php"; end
    
    def post_collection_uri; "#{blog_uri}/wp-app.php/posts"; end
    def service_uri; "#{blog_uri}/wp-app.php/service"; end
    
    def publish_post post
      raise "Post cannot be nil" if post == nil
      raise "You can only publish valid Atom::Entry items" unless post.class == Atom::Entry
      Atom::Pub::Collection.new(:href => post_collection_uri).publish(post, :user => username, :pass => password)
    end
    
    def add_category opts = {}
      login!
      unless category_exists? opts
        page = agent.get("#{blog_uri}/wp-admin/edit-tags.php?taxonomy=category")
        form = page.form_with(:action => "edit-tags.php")
        form.send(:"tag-name",opts[:term])
        form.slug = opts[:scheme]
        form.description = opts[:description]
        agent.submit(form, form.buttons.first)
      end
    end
    
    def category_exists? opts
      exists = false
      uri = URI.parse(blog_uri + '/wp-app.php/categories')
      content = Net::HTTP.start(uri.host) do |http|
        req = Net::HTTP::Get.new(uri.path)
        req.basic_auth username, password
        response = http.request(req)
        response.body
      end
      doc = Nokogiri::XML(content)
      doc.search("category").each do |cat|
        exists = true if cat.attr("term") == opts[:term]
      end
      exists
    end
  end
end

# Go for it
puts "#{Time.now} Initializing link..."
blog = Wordpress::Blog.new("http://wordpress.smackaho.st:4567","admin","adminadmin")
 
[{:term => "facebook", :label => "Facebook Message", :scheme => "facebook"},{:term => "tumblr", :label => "Tumblr Message", :scheme => "tumblr"}].each do |post_cat|
  unless blog.category_exists? post_cat
    puts "#{Time.now} Creating new category ..."
    blog.add_category post_cat
  end
end

%W{advanced-excerpt json-api wp-pagenavi}.each do |plugin|
  puts "#{Time.now} Enabling Plugin #{plugin} ..."
  blog.enable_plugin(plugin)
end 

puts "#{Time.now} Enabling json-api controllers ..."
blog.enable_json_api
puts "#{Time.now} Enabling permalinks ..."
blog.enable_permalinks  
puts "#{Time.now} Enabling theme ..."
blog.enable_theme("paragrams")  
puts "#{Time.now} Customize Advanced Exc ..."
blog.custom_excerpt