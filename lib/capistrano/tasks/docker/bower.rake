namespace :docker do
  namespace :bower do
    task :install do
      on roles(fetch(:docker_role)) do
        execute :docker, task_command(fetch(:docker_bower_install_command))
      end
    end
  end
end

before "docker:deploy:default:run", "docker:bower:install"
