namespace :docker do
  namespace :compose do
    task :start do
      invoke "docker:deploy:compose:start"
    end

    task :stop do
      invoke "docker:deploy:compose:stop"
    end
  end

  namespace :deploy do
    task :compose do
      %w( validate start ).each do |task|
        invoke "docker:deploy:compose:#{task}"
      end
    end

    namespace :compose do
      task :validate do
        fetch(:docker_pass_env).each do |env|
          raise "missing #{env} environment variable" if ENV[env].nil?
        end
      end

      task :start do
        on roles(fetch(:docker_role)) do
          within release_path do
            execute :"docker-compose", compose_start_command
          end
        end
      end
      before :start, "docker:prepare_environment"

      task :stop do
        on roles(fetch(:docker_role)) do
          within release_path do
            execute :"docker-compose", compose_stop_command
            execute :"docker-compose", compose_remove_command unless fetch(:docker_compose_remove_after_stop) == false
          end
        end
      end
      before :stop, "docker:prepare_environment"
    end
  end

  def compose_start_command
    cmd = ["up"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << "-d"

    cmd.join(" ")
  end

  def compose_stop_command
    cmd = ["stop"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?

    cmd.join(" ")
  end

  def compose_remove_command
    cmd = ["rm"]
    cmd.unshift("-p #{fetch(:docker_compose_project_name)}") unless fetch(:docker_compose_project_name).nil?
    cmd << "-fv"

    cmd.join(" ")
  end
end
