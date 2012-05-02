include_recipe "nginx::source"
include_recipe "redis::source"
include_recipe "mongodb"
include_recipe "monit"
include_recipe "ruby_build"
include_recipe "rbenv::system_install"

node[:pingit] ||= {}
node[:pingit][:ruby_version] = "1.9.3-p194"
node[:pingit][:web_port] = "3000"
#node[:pingit][:ruby_version] = "jruby-1.6.7"

rbenv_ruby node[:pingit][:ruby_version] do
  action :install
end

rbenv_gem "bundler" do
  rbenv_version node[:pingit][:ruby_version]
end

# Package needed by nokogiri
package 'libxml2'
package 'libxml2-dev'
package 'libxslt1-dev'

rbenv_script "bundle install" do
  rbenv_version node[:pingit][:ruby_version]
  code "bundle install --binstubs --path vendor/bundle"
  cwd "/vagrant"
end

directory "/var/run/pingit" do
  owner "vagrant"
  recursive true
  action :create
end

file '/vagrant/env' do
  owner 'vagrant'
  content <<-EOF
export HOME=/vagrant
export PATH=/usr/local/rbenv/shims/:/usr/local/rbenv/bin:$PATH
export RBENV_VERSION=#{node[:pingit][:ruby_version]}
export RAILS_ENV=development
export UNICORN_WORKER_PROCESS=1
export UNICORN_LISTEN=#{node[:pingit][:web_port]}
export UNICORN_PID=/var/run/pingit/unicorn.pid
export REDIS_URL=redis://localhost:6379
export UNICORN_STDOUT_PATH=/vagrant/log/unicorn_stdout.log
export UNICORN_STDERR_PATH=/vagrant/log/unicorn_stderr.log
  EOF
end

monitrc 'pingit_dev'

template "/etc/nginx/sites-available/pingit_dev.conf" do
  source 'pingit_dev.nginx.erb'
  variables({
    :listen_port => node[:pingit][:web_port],
    :host => 'pingit.dev',
    :public_path => '/vagrant/public'
  })
end

nginx_site 'pingit_dev.conf'
