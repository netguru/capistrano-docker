namespace :docker do
  namespace :current do
    task :rebuild do
      on roles(fetch(:docker_role)) do
        within release_path do
          execute :docker, build_command
        end
      end
    end

    task :restart do
      invoke 'docker:current:stop'
      invoke 'docker:current:start'
    end

    task :start do
      if fetch(:docker_compose) == true
        invoke "docker:compose:start"
      else
        on roles(fetch(:docker_role)) do
          execute start_container(fetch(:docker_current_container))
        end
      end
    end

    task :stop do
      if fetch(:docker_compose) == true
        invoke "docker:compose:stop"
      else
        on roles(fetch(:docker_role)) do
          execute stop_container(fetch(:docker_current_container))
        end
      end
    end

    before :start, "docker:current_revision"
    before :stop, "docker:current_revision"
  end

  def start_container(container_name)
    "docker start #{container_name}"
  end

  def stop_container(container_name)
    "docker stop #{container_name}"
  end
end
