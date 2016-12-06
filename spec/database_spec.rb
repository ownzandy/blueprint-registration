require 'spec_helper'
require 'rails_helper'
require 'event_helper'
require 'heroku_helper'
require 'rake'
require 'database_tester'
require_relative '../app/modules/typeform_data'
require_relative '../app/modules/typeform_util'
require_relative '../app/modules/mailchimp_util'

describe 'Database Synchronization' do
  include TypeformData
  include TypeformUtil
  include MailchimpUtil
  include EventHelper

  before :all do
    HackDukeAPI::Application.load_tasks
    system 'bin/rails db:environment:set RAILS_ENV=test'
  end

  describe 'Typeform and Mailchimp', :type => :request do
    it 'pull all data from typeform and maintain accuracy over multiple runs as well
        as compare email lists on mailchimp to database values before and after modification' do

      database_tester = DatabaseTester.new
      active_events = Event.where(active: 1)

      puts 'Generating person hash...'
      person_hash = database_tester.generate_person_hash(active_events)

      valid_database = true 
      puts 'Cross-checking the database with the data API...'
      person_hash.each do |email, attribute_hash|
        if !database_tester.validate_person_hash(person_hash, email, attribute_hash)
          valid_database = false
        end
      end

      expect(valid_database).to eql(true)


      Rake::Task['database:prepare'].invoke
      create_events_from_prod
      puts 'Generating typeform responses from data API...'
      all_responses = generate_all_responses
      populate_database(all_responses, 1, 10)
      puts 'Generating typeform responses from data API...'
      all_responses = generate_all_responses
      populate_database(all_responses, 2, 1)

      valid_database = true 
      puts 'Cross-checking the database with the data API...'
      person_hash.each do |email, attribute_hash|
        if !database_tester.validate_person_hash(person_hash, email, attribute_hash)
          valid_database = false
        end
      end

      expect(valid_database).to eql(true)


      # puts ''
      # puts 'Making code_for_good spring 2000 (test event) and design_con spring 2016 the only active events...'
      # active_events.each do |active_event|
      #   active_event.active = 0
      #   active_event.save!
      # end
      # events = []
      # events << Event.joins(:semester).where('semesters.year = ? AND semesters.season = ? AND event_type = ?', 2000, 
      #                                         Semester.seasons['spring'], Event.event_types['code_for_good']).first
      # events << Event.joins(:semester).where('semesters.year = ? AND semesters.season = ? AND event_type = ?', 2016, 
      #                                         Semester.seasons['spring'], Event.event_types['design_con']).first
      # events = events.select{|event| event != nil}
      # expect(events.length).to eql(2)

      # puts 'Randomly assigning stauses to participants...'
      # events.each do |event|
      #   event.active = 1
      #   event.save!
      #   Participant.where(event_id: event.id).each do |participant|
      #     participant.status = rand(Participant.statuses.keys.size)
      #     participant.save!
      #   end
      # end

      # puts 'Invoking mailchimp resque job to sync up mailchimp... (this takes a while...)'
      # Rake::Task['resque:mailchimp'].invoke

      # puts 'Sleeping for 5 minutes to allow changes to propagate on mailchimp...'
      # sleep 300

      # Event.where(active: 1).each do |event|
      #   puts "Validating mailchimp lists for #{event.event_type} #{event.semester.season} #{event.semester.year}"
      #   emails_array = retrieve_emails_for_event(event)
      #   emails_array.each_with_index do |array, index|
      #     participant_offset = Participant.statuses.keys.size
      #     status = Participant.statuses.keys[index]
      #     if index < participant_offset
      #       database_emails_array = Participant.where(status: index, event_id: event.id).map{|participant| participant.person.email}
      #       expect(compare_emails(array, filter_invalid_emails(database_emails_array), 
      #                             "participant #{status}", event)).to eql(true)
      #     else
      #       role_index = index + 1 - participant_offset
      #       role = Person.roles.keys[role_index]
      #       model = role.classify.constantize
      #       database_emails_array = model.where(event_id: event.id).map{|role| role.person.email}
      #       expect(compare_emails(array, filter_invalid_emails(database_emails_array), 
      #                             role, event)).to eql(true)
      #     end
      #   end
      # end
      
    end
  end

  def compare_emails(mailchimp_list, database_list, role, event)
    a = mailchimp_list
    b = database_list
    diff = (a - (a & b)) | (b - (a & b)) 
    if diff.size > 0
      print_email_info(diff, a, b, role, event)
    end
    diff.size == 0
  end

  def print_email_info(diff, a, b, role, event)
    puts ""
    puts "Errors found in mailchimp list for #{event.event_type} #{event.semester.season} #{event.semester.year} #{role}"
    puts "The following emails were different: #{diff.join(', ')}"
    puts "There are #{a.size} emails on mailchimp but #{b.size} emails in the database"
  end

  def populate_database(all_responses, i, time_chunk)
    puts "Populating database with responses for the #{i.ordinalize} time"
    start_time = Time.now
    largest_diff = 0
    all_responses.each_with_index do |r, index|
      if r[:route].include? '.json'
        r[:route].slice! '.json'
      end
      post(r[:route], params: r[:params][:body], env: {'HTTP_AUTHORIZATION': credentials}, as: :json)
      time = Time.now.minus_with_coercion(start_time).round
      if time % time_chunk == 0 && time > largest_diff
        largest_diff = time
        puts "There are #{Person.all.count} people in the database at #{time} seconds"
      end
    end
  end

end
 
