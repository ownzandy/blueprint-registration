require 'logger'
require 'typeform_util'
require 'typeform_data'
require 'mailchimp_util'

# this module contains logic to add form_ids to an event and
# handles the creation, deletion, and initial subscription to mailchimp lists

module EventsUtil
  include TypeformUtil
  include TypeformData
  include MailchimpUtil

  def add_form_info(id, event)
    typeform_forms_api_url = 'https://api.typeform.com/v0/forms?key=' + Rails.application.secrets.typeform_api_key
    all_forms = ActiveSupport::JSON.decode(HTTParty.get(typeform_forms_api_url).body)
    all_forms.each do |form|
      if form['id'] == id && !event.form_ids.include?(form['id'])
        typeform_data_api_url = data_api_url(id)
        form_object = ActiveSupport::JSON.decode(HTTParty.get(typeform_data_api_url).body) 
        route = get_data_route(form_object['questions'])
        # update routes are added to the end while receive routes are added to the beginning
        # because receive routes must be processed first 
        if route.include? 'update'
          event.form_names << form['name']
          event.form_routes << route.join('_')
          event.form_ids << id
        elsif route.include? 'receive'
          event.form_names.unshift form['name']
          event.form_routes.unshift route.join('_')
          event.form_ids.unshift id
        end
      end
    end
    event.save!
  end

  def get_slack_users
    users = HTTParty.get('https://slack.com/api/users.list?token=' + Rails.application.secrets.slack_token)
    #email to slack ID
    users["members"]
  end


end