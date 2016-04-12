namespace :docker do
  namespace :migration do
    task :create do
      on roles(fetch(:docker_role)) do
        execute :docker, task_command(fetch(:docker_db_create_command))
      end
    end
    
    task :migrate do
      on roles(fetch(:docker_role)) do
        execute :docker, task_command(fetch(:docker_migrate_command))
      end
    end
  end
end

before "docker:deploy:default:run", "docker:migration:migrate"
