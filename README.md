# Capistrano - Docker strategy deployment

This gem allows you to easily deploy applications based on Docker images. It allows you to deploy apps two ways:

    1. Using default docker strategy (build, run etc)
    2. Using docker-compose strategy

### Installation

To get started you need to have:

    1. A project with existing Dockerfile
    2. A capistrano >= 3.2 version already hooked to your project

First - add following file to your gemfile:

    gem 'capistrano-docker', github: 'netguru/capistrano-docker'

Next, add following to your `Capfile`:

    require 'capistrano/docker'

If you want to deploy via docker strategy only on a specific stage, you can include these tasks only to a specific stage, like:

    task :docker do
      require 'capistrano/docker'
    end

    task 'staging' => [:docker]

This will loadup docker tasks only in `staging` stage.

There are additional tasks available, which are run once in a seperate container, using configured links / volumes. The tasks are:

    require 'capistrano/docker/assets' - precompile assets
    require 'capistrano/docker/migration' - run db:migrate
    require 'capistrano/docker/npm' - run npm install
    require 'capistrano/docker/bower' - run bower install


Next, optionally, specify the options in your `config/stage/deploy.rb` file, however the defaults provided should work out-of-the-box.

    set :docker_current_container - the name of used container, defaults to: APPNAME_REVISION
    set :docker_role - the name of the role which is used for Docker host, defaults to ':web'
    set :docker_pull - related to building an image, should we always pull the baseimage, defaults to false
    set :docker_dockerfile - specify the path to the Dockerfile (relative from project root directory), defaults to project root directory
    set :docker_buildpath - the buildpath of the image, defaults to project root directory ( . )
    set :docker_detach - should we detach when running the container (the '-d' option in docker run), defaults to true
    set :docker_volumes - an array of volumes we want to hook up, defaults to empty
    set :docker_restart_policy - specify the restart policy of the container, defaults to 'always', if nil given, no policy will be applied
    set :docker_links - specify an array of links to other containers
    set :docker_labels - specify an array of labels that can be added to a container at runtime, defaults to empty, however the label that is always added is: git.revision.id=REVISION
    set :docker_image - the name of the image that will be used, defaults to: APPNAME_STAGE
    set :docker_image_full - name of the image with a tag, defaults to APPNAME_STAGE:REVISION
    set :docker_additional_options - additional options that will be passed to the 'docker run' command, defaults to none
    set :docker_copy_data - docker does not allow us to use symlinks so this is just a substitute for linked_files (and linked_dirs), however instead of linking it simply copy the contents, so these will be visible inside image
    set :docker_cpu_quota - specify the value for --cpu-quota option when running containers (does not work with docker-compose)
    set :docker_apparmor_profile - run docker containers with specified apparmor profile


    set :docker_compose - should we use docker-compose strategy instead (note - all above options are obsolete using this option), using docker-compose requires you to have docker-compose.yml file in your root directory, defaults to false
    set :docker_compose_project_name - prefix for the container names, defaults to nil, so it defaults to the directory name the project is at
    set :docker_compose_remove_after_stop - should we remove the containers after stopping them, defaults to true
    set :docker_compose_remove_volumes - should we remove associated volumes with containers during their removal (rm -v option), default: true
    set :docker_compose_build_services - specify services which should be built / ran with docker-compose (ex. docker-compose build web), default: none
    set :docker_pass_env - the list of the environment variables that should be passed over to the docker-compose commands from command line (they are validated wether they exists before they are used) (ex: PULL_REQUEST_ID=10 cap staging docker:compose:start )
    set :docker_assets_precompile_command - command to be executed as assets precompile task (when capistrano/docker/assets is used, defaults to 'rake assets:precompile')
    set :docker_migrate_command - command to be executed as migration task (when capistrano/docker/migration is used, defaults to 'rake db:migrate')
    set :docker_npm_install_command - command to be executed for installing npm packages, defaults to 'npm install --production --no-spin'
    set :docker_bower_install_command - command to be executed for intalling bower packages, defaults to 'bower install --production'

The docker tasks will attach themselves just after default `deploy:updated` task from capistrano.

### Docker default strategy overview

Step-by-step what default strategy does:

    1. prepares the build, copying over files and folders described in "docker_copy_data" option
    2. builds the image based on the given Dockerfile, tagging it with "docker_full_image"
    3. runs the containers based on built image, attaching volumes, links, labels etc
    4. cleans previous containers - it finds previously running containers, stopping and removing them (images of those containers are not removed)
    5. tags the new running container with :latest tag

### Docker compose strategy overview

Using docker-compose strategy is a bit smaller and easier, however I would not recommend using this strategy on production, as docker-compose itself isn't production-ready

    1. validate wether we passed over the environment variables described in "docker_pass_env"
    2. it runs docker-compose up with project_name and detached options

Docker-compose strategy is not stopping the containers automatically. You can use the "docker:compose:stop" task to do that (just remember that this will remove any compose-created containers unless you change the "docker_compose_remove_after_stop" option)


### Changelog

#### 0.2.8

`#docker-compose` Added option to specify service name to be built / ran if docker-compose file contains multiple environments.
For example if you have services like:
```
dev:
    build: .
    dockerfile: Dockerfile.dev
    ...

staging:
    build: .
    dockerfile: Dockerfile.staging
    ...
```

and you want to "run" only `staging` service, then add to deploy option: `set :docker_compose_build_services, -> { "staging" }`

#### 0.2.7

`#docker-compose` Added option to specify wether we want to remove associated volumes when stopping / removing docker-compose containers, defaults to true

#### 0.2.6

Added option to set cpu quota for containers (`:docker_cpu_quota`) - does not work with docker-compose

#### 0.2.5

Added two additional tasks which can be ran just before container. Add to Capfile:

    require 'capistrano/docker/npm' - for running npm install
    require 'capistrano/docker/bower' - for running bower install


#### 0.2.4

Two new tasks added that can be ran just before running a container: assets:precompile and db:migrate
Add to Capfile:

    require 'capistrano/docker/assets' - for asset task
    require 'capistrano/docker/migration' - for migration task

See installation section for more info


#### 0.2.3

You can add a custom apparmor profile that will apply to running new containers by setting `docker_apparmor_profile` variable

#### 0.2.2

Docker compose now copies over `docker_copy_data` files to the release path before build

#### 0.2.1

Docker compose now always rebuilds images before running them
