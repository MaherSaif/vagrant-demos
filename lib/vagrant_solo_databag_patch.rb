CHEF_REPO = "../chef_repo" # path to chef repo,
# because Vagrantfile is normally in application repo, not in chef repo.
# see also https://gist.github.com/867960 for chef_solo patch

module Vagrant
  module Provisioners
    class ChefSolo
      class Config
        attr_accessor :data_bag_path
      end

      def prepare
        share_cookbook_folders
        share_role_folders
        share_data_bag_folder
      end

      def share_data_bag_folder
        if config.data_bag_path
          env.config.vm.share_folder("v-csd-0", folder_path("data_bags"), File.expand_path(config.data_bag_path, env.root_path))
        end
      end

      def setup_config(template, filename, template_vars)
        config_file = TemplateRenderer.render(template, {
          :log_level => config.log_level.to_sym,
          :http_proxy => config.http_proxy,
          :http_proxy_user => config.http_proxy_user,
          :http_proxy_pass => config.http_proxy_pass,
          :https_proxy => config.https_proxy,
          :https_proxy_user => config.https_proxy_user,
          :https_proxy_pass => config.https_proxy_pass,
          :no_proxy => config.no_proxy
        }.merge(template_vars))
        config_file += "\ndata_bag_path \"%s\"\n" % folder_path("data_bags")
        vm.ssh.upload!(StringIO.new(config_file), File.join(config.provisioning_path, filename))
      end

    end
  end
end


# use it like this:
#  config.vm.provision :chef_solo do |chef|
#    chef.cookbooks_path = "#{CHEF_REPO}/cookbooks"
#    chef.roles_path = "#{CHEF_REPO}/roles"
#    chef.data_bag_path = "#{CHEF_REPO}/data_bags"
#    #... etc
#  end