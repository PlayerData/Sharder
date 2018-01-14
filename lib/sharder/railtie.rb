class Sharder
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/sharder_tasks.rake"
    end
  end
end
