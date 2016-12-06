require 'typeform_util'

# this module contains logic to ingest the typeform data API
# ths main resque job method can be found in resque/typeform.rb
# and prepare the data to call the receive/update_person endpoint
# see the bottom of this file for sample JSON

module TypeformData
  include TypeformUtil

  def generate_all_responses
    responses_array = []
    remove_all_submission_history
    Event.where(active: 1).each do |event| 
      event.form_ids.each_with_index do |form_id, index|
        form_object = ActiveSupport::JSON.decode(HTTParty.get(data_api_url(form_id)).body)
        
        # enumerates all and increments offset if necessary
        responses = form_object['responses']
        offset = 1000
        while form_object['responses'].length == 1000
          form_object = ActiveSupport::JSON.decode(HTTParty.get(data_api_url(form_id, offset)).body)
          responses += form_object['responses']
          offset += 1000
        end

        route = get_data_route(form_object['questions'])
        if route == ''
          no_route_error(form_id)
          return
        end
        action = route[1]
        role = route[2]

        responses.each do |r|
          responses = {}
          responses.merge!({:params => process_form(r, event, form_id, form_object['questions'],
                                                     r['hidden']['email'], role)})
          responses.merge!({:route => "/people/#{action}_role"})
          responses.merge!({:response => r})
          responses.merge!({:event => event}) 

          responses_array << responses

        end
      end
    end
    responses_array
  end 

  def process_form(response, event, form_id, questions, hidden_email, role)
    person = create_info_hash(Person, response, questions)
    replace_email_if_necessary(hidden_email, person)
    # classify.constantize gives us the model object (Participant, Mentor, etc.)
    model = role.classify.constantize
    role_hash = create_info_hash(model, response, questions)
    role_sym = role.parameterize.underscore.to_sym 
    options = { body: { form_id: form_id, person: person, role_sym => role_hash, role: role,
              submit_date: DateTime.parse(response["metadata"]["date_submit"])} }
    options.merge!({basic_auth: {username: Rails.application.secrets.username, 
                               password: Rails.application.secrets.password}})
  end

  def data_api_url(fid, offset=0)
    typeform_data_api_url = 'https://api.typeform.com/v0/form/' + fid+ '?key=' + 
                            Rails.application.secrets.typeform_api_key + 
                            '&completed=true&order_by[]=date_submit&offset=' + offset.to_s
  end

  # loops through all the attributes/column_names of the model (participant, mentor, etc.)
  # and extracts relevant questions
  def create_info_hash(model, response, questions)
    hash = {}
    model.column_names.each do |field|
      result = extract_result(field, response, questions)
      result = result.select{|result| result != '' && result != nil}
      add_result_to_hash(hash, field, result, model)
    end
    hash
  end

  def add_result_to_hash(hash, field, result, model)
    # don't add empty links with just https://
    if result.include? 'http://'
      return
    end
    if valid_result(result, field)
      result = handle_results_array_by_field(model, field, result)
      # logic to make sure we don't get nils in our arrays
      if result != nil
        if result.kind_of? Array
          if !result.include? nil
            hash[field] = result
          end
        else
          hash[field] = result
        end
      end
    end
  end

  def extract_result(field, response, questions) 
    if field == "custom"
      determine_custom(response, questions)
    else
      determine_regular(response, field, questions)
    end
  end

  def determine_regular(response, field, questions)
    result = []
    questions.each do |q|
      if correct_question(field, q) && !q['question'].include?('Q:')
        answer = response['answers'][q['id']]
        if answer != nil 
          answer.force_encoding('UTF-8')
        end
        result << answer unless answer == ''
      end
    end
    result
  end

  def determine_custom(response, questions)
    result = []
    determine_custom_questions(questions).each do |q|
      answer = response['answers'][q['id']]
      if answer != '' && answer != nil
        answer.force_encoding('UTF-8')
        result << q['question']
        result << answer
      end
    end
    result
  end

  def determine_custom_questions(questions)
    custom_questions = []
    questions.each do |q|
      if q['question'].include? 'Q:'
        custom_questions << q
      end
    end
    custom_questions
  end

  def correct_question(field, question) 
    correct_question = true
    field.split('_').each do |f|
      if !split_clean_question(question['question']).include? f
        correct_question = false
      end
    end
    correct_question
  end

end

# "questions": [
#   {
#     "id": "textfield_20105439",
#     "question": "What's your first name?",
#     "field_id": 20105439
#   },
#   {
#     "id": "list_20105443_choice",
#     "question": "What is your gender?",
#     "field_id": 20105443
#   },
#   {
#     "id": "list_20105443_other",
#     "question": "What is your gender?",
#     "field_id": 20105443
#   },
#   {
#     "id": "textarea_22216151",
#     "question": "Q: Tell us about your design experience.",
#     "field_id": 22216151
#   },
#   {
#     "id": "hidden_route_receive_participant",
#     "question": "route_receive_participant",
#     "field_id": 150732
#   }
# ],
# "responses": [
#   {
#     "hidden": {
#       "route_receive_participant": "xxxxx"
#     },
#     "answers": {
#       "textfield_20105439": "Joe",
#       "list_20105443_choice": "Female",
#       "list_20105443_other": "",
#       "textarea_22216134": "asdsdad",
#       "textarea_22216151": "kldfjglsdglsdfb"
#     }
#   }
# ]

