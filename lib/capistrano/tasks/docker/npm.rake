namespace :docker do
  namespace :npm do
    task :install do
      on roles(fetch(:docker_role)) do
        execute :docker, task_command(fetch(:docker_npm_install_command))
      end
    end
  end
end

before "docker:deploy:default:run", "docker:npm:install"
