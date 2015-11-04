namespace :deploy do
  after :updated, 'docker:deploy'
end
