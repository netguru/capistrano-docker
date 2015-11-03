namespace :docker do
  task :release do
    %w( prepare build run clean tag ).each do |task|
      invoke "docker:release:#{task}"
    end
  end

  namespace :release do
    desc "Prepares docker for building"
    task :prepare do
      on roles(fetch(:docker_role)) do
        within release_path do
          fetch(:docker_copy_data).each do |file|
            execute :cp, " -aR #{shared_path}/#{file} #{release_path}/#{file}"
          end
        end
      end
    end

    task :build do
      on roles(fetch(:docker_role)) do
        within release_path do
          execute :docker, build_command
        end
      end
    end

    task :run do
      on roles(fetch(:docker_role)) do
        invoke 'docker:release:clean_current' if running?
        execute :docker, run_command
      end
    end
    before :run, "docker:current_revision"

    task :clean_current do
      on roles(fetch(:docker_role)) do
        execute stop_container(fetch(:docker_current_container))
        execute remove_container(fetch(:docker_current_container))
        execute remove_image("#{fetch(:docker_image)}:current"), raise_on_non_zero_exit: false
      end
    end
    before :clean_current, "docker:current_revision"

    task :clean do
      on roles(fetch(:docker_role)) do
        old_containers.each do |id, image, rev|
          if rev != fetch(:current_revision)
            execute stop_container(id)
            execute remove_container(id)
            execute remove_image(image), raise_on_non_zero_exit: false
          end
        end
      end
    end
    before :clean, "docker:current_revision"

    task :tag do
      on roles(fetch(:docker_role)) do
        execute :docker, "tag -f #{fetch(:docker_image_full)} #{fetch(:docker_image)}:current"
      end
    end
  end

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
      on roles(fetch(:docker_role)) do
        execute start_container(fetch(:docker_current_container))
      end
    end

    task :stop do
      on roles(fetch(:docker_role)) do
        execute stop_container(fetch(:docker_current_container))
      end
    end

    before :start, "docker:current_revision"
    before :stop, "docker:current_revision"
  end

  task :current_revision do
    invoke "#{scm}:set_current_revision"
  end

  def running?
    cmd = %(docker ps -f "name=#{fetch(:docker_current_container)}" --format '{{.Status}}')
    capture(cmd).match(/^Up.+/)
  end

  def old_containers
    cmd = %(docker ps -f "name=#{fetch(:application)}_" --format '{{.ID}} {{.Image}} {{.Label "git.revision.id"}}' | grep "#{fetch(:docker_image)}")
    capture(cmd).split("\n").map { |x| x.split(" ") }
  end

  def remove_container(container)
    "docker rm #{container}"
  end

  def remove_image(image)
    "docker rmi #{image}"
  end

  def start_container(container_name)
    "docker start #{container_name}"
  end

  def stop_container(container_name)
    "docker stop #{container_name}"
  end

  def build_command
    cmd = ["build"]
    cmd << "-t #{fetch(:docker_image_full)}"
    cmd << "-f `pwd -P`/#{fetch(:docker_dockerfile)}"
    cmd << "--pull" if fetch(:docker_pull) == true
    cmd << fetch(:docker_buildpath)

    cmd.join(" ")
  end

  def run_command
    cmd = ["run"]
    cmd << "-d" if fetch(:docker_detach) == true
    cmd << "--name #{fetch(:docker_current_container)}"

    # attach volumes
    fetch(:docker_volumes).each do |volume|
      cmd << "-v #{volume}"
    end

    # attach links
    fetch(:docker_links).each do |link|
      cmd << "--link #{link}"
    end

    # attach labels
    fetch(:docker_labels).each do |label|
      cmd << "--label=#{label}"  ## example: com.example.key=value
    end

    # attach revision label
    cmd << "--label=git.revision.id=#{fetch(:current_revision)}"

    cmd << "--restart #{fetch(:docker_restart_policy)}" unless fetch(:docker_restart_policy).nil?
    cmd << fetch(:docker_additional_options)
    cmd << fetch(:docker_image_full)

    cmd.join(" ")
  end
end

namespace :load do
  task :defaults do
    set :docker_current_container,  -> { "#{fetch(:application)}_#{fetch(:current_revision)}" }
    set :docker_previous_container, -> { "#{fetch(:application)}_#{fetch(:previous_revision)}" }
    set :docker_role,               -> { :web }
    set :docker_pull,               -> { false }
    set :docker_dockerfile,         -> { "Dockerfile" }
    set :docker_buildpath,          -> { "." }
    set :docker_detach,             -> { true }
    set :docker_volumes,            -> { [] }
    set :docker_restart_policy,     -> { "always" }
    set :docker_links,              -> { [] }
    set :docker_labels,             -> { [] }
    set :docker_image,              -> { "#{fetch(:application)}_#{fetch(:stage)}" }
    set :docker_image_full,         -> { [fetch(:docker_image), fetch(:docker_tag)].join(":") }
    set :docker_tag,                -> { "latest" }
    set :docker_additional_options, -> { "" }
    set :docker_copy_data,          -> { [] }
  end
end
