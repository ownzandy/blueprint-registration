
namespace :database do

  task prepare: :environment do
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
  end

  task drop: :environment do
    Rake::Task['db:drop'].invoke
  end

end
