namespace :deploy do
  after :updated, 'docker:release'
end
