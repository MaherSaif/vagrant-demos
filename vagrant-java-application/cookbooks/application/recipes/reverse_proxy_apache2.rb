
app = node.run_state[:current_app]

web_app "client" do
  template "reverse_proxy.erb"
  server_name app['domain_name']
  server_aliases app['domain_name_aliases'].split(",") if app['domain_name_aliases']
  frontend_path "/"
  backend_host "localhost"
  backend_port "8080"
  backend_path "/"
end




