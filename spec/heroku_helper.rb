module HerokuHelper

  def heroku(command)
    system("GEM_HOME='' BUNDLE_GEMFILE='' GEM_PATH='' RUBYOPT='' /usr/local/heroku/bin/heroku #{command}")
  end

end