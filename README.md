#HackDuke API
[![Build Status](https://travis-ci.org/hack-duke/hackduke-api.svg?branch=master)](https://travis-ci.org/hack-duke/hackduke-api)

##Overview
This API serves to facilitate registration for all HackDuke events through typeform. The use of typeform allows
the quick creation of forms for any event given that the questions have a corresponding field in the database. See the hackduke-typeform repo for comprehensive instructions for how typeforms should be created.

##Project Structure
- app/controllers/people_controller.rb and its modules contains most of the logic to receive webhooks/posts to modify/add people to the database
- lib/tasks contain several rake tasks (mailchimp, typeform, judgebot) and resque (job-scheduler) configuration
- pusher configuration can be found in config/initializers
- utility modules should go in app/modules
- tests can be found in the spec folder

##Getting Started
- download postgresql at http://postgresapp.com/ (for mac)
- use rbenv for ruby versioning (currently on 2.2.3)
- run cp ../hackduke-secrets/.env-hackduke-api .env (assuming that
hackduke-secrets and hackduke-api share the same parent folder)
- run bundle install and then rails s (there may be complications)
- if you're having trouble with nokogiri, you may have to run xcode-select --install
- pull database from heroku (heroku pg:pull DATABASE_URL hackduke-api_development, ask for access)

##Merging changes
Make sure to squash all commits upon merge, using Github's "squash and merge" functionality. 

##Spacing
Please use 2 spaces to indent

##Testing
- Run the following to start the mailchimp + typeform integration test
```
dropdb travis_ci_test
heroku pg:pull DATABASE_URL travis_ci_test --app hackduke-api
bundle exec rspec spec
```
- If the mailchimp test is failing, it may be because mailchimp is responding too slowly (try again)
or there have been invalid emails added (you can filter them out in the MailchimpUtil module to get 
the test to pass again)

##Services
- Mailchimp: bundle exec rake resque:mailchimp
- The services below are currently not ready to be used in production because they will send mass welcome emails
- Mailchimp synchronization can be performed manually on Heroku whenever needed
- Typeform: bundle exec rake resque:typeform
- Crons (typeform, mailchimp): bundle exec rake resque:scheduler (see scheduler at config/schedule.yml)
- Run bundle exec rake resque:work QUEUE=high and redis-server before the scheduler is started

##Deployment instructions
- currently using heroku for deployment
- replace bundle exec with heroku run to run services on heroku

##Continous integration
- currently using travis CI to run the tests on every build and deploy to heroku on merges to master
