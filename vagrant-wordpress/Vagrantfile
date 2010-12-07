Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. For a detailed explanation
  # and listing of configuration options, please view the documentation
  # online.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "base"                 

  # Forward guest port 80 to host port 4567 and name the mapping "web"
  config.vm.forward_port("web", 80, 4567)   
  
  # This path will be expanded relative to the project directory
  config.chef.cookbooks_path = "cookbooks"
  # ensure the latest packages
  config.chef.add_recipe("apt") 
  
  #this recipe we want to run
  config.chef.add_recipe("wordpress_demo") 
  
  config.chef.json.merge!({
      :mysql => {
        :server_debian_password => "secure_password",
        :server_root_password => "secure_password",
        :server_repl_password => "secure_password"
      }
    })
  
  # we use chef-solo to provision stuff
  config.vm.provisioner = :chef_solo
end
