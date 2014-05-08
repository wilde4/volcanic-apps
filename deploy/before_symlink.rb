Chef::Log.info("==== Hello!")
run "cd #{release_path} && RAILS_ENV=production bundle exec rake assets:precompile"

# # Chef::Log.info("Running deploy/before_migrate.rb...")
# # 
# # Chef::Log.info("Symlinking #{release_path}/public/assets to #{new_resource.deploy_to}/shared/assets")
# # 
# # link "#{release_path}/public/assets" do
# #   to "#{new_resource.deploy_to}/shared/assets"
# # end
# # 
# # rails_env = new_resource.environment["RAILS_ENV"]
# # Chef::Log.info("Precompiling assets for RAILS_ENV=#{rails_env}...")
# 
# Chef::Log.info("==== Compilation of Assets")
# 
# # execute "rake assets:precompile" do
# #   cwd release_path
# #   command "bundle exec rake assets:precompile"
# #   environment "RAILS_ENV" => rails_env
# # end
# 
# 
# execute 'rake assets:precompile' do
#   cwd "#{node[:deploy_to]}/current"
#   # cwd "#{node[:deploy_to]}/current"
#   # user 'root'
#   # command 'bundle exec rake assets:precompile'
#   # environment 'RAILS_ENV' => node[:environment_variables][:RAILS_ENV]
# end