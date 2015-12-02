namespace :docker do
  namespace :assets do
    task :precompile do
      on roles(fetch(:docker_role)) do
        execute :docker, task_command(fetch(:docker_assets_precompile_command))
      end
    end
  end
end

before "docker:deploy:default:run", "docker:assets:precompile"
