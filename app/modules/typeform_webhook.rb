require 'typeform_util'

# this module contains logic to ingest the typeform webhook 
# and prepare the data for the receive/update logic
# see https://www.typeform.com/help/webhooks/#payload for sample JSON
# does not support the payment question

module TypeformWebhook
  include TypeformUtil

  # similar logic to process_form in typeform_data.rb
  # creates info hashes for the person and the person's role
  def parse_push_json(params)
    form_response = params[:form_response].to_unsafe_h
    route = get_webhook_route(form_response)
    if route == ''
      no_route_error(form_response[:form_id])
      return {}
    end
    role = route[2]

    parts = find_parts(form_response)
    person = create_webhook_info_hash(Person, form_response[:definition][:fields], form_response[:answers])
    replace_email_if_necessary(hidden_email, person)
    hidden_email = form_response[:hidden]['email']
    params = { form_id: form_response[:form_id], person: person, 
      submit_date: DateTime.parse(form_response[:submitted_at]), parts: find_parts(form_response)} 
    parts.each do |role_name|
      role = role_name.classify.constantize
      role_hash = create_webhook_info_hash(model, form_response[:definition][:fields], form_response[:answers])
      role_sym = role.parameterize.underscore.to_sym 
      params[:role_sym] = role_hash
    end
    params 
  end

  def create_webhook_info_hash(model, fields, answers)
    hash = {}
    if fields != nil 
      model.column_names.each do |model_field|
        result = extract_webhook_result(fields, model_field, answers) 
        if valid_result(result, model_field)
          result = handle_results_array_by_field(model, model_field, result)
          hash[model_field.to_sym] = result
        end
      end
    end
    hash
  end

  def find_parts(form_response)
    parts = []
    result = extract_webhook_result(form_response[:definition][:fields], 'part', form_response[:answers])
    result.each do |part|
      if part == 'Student Participant'
        parts << 'participant'
      elsif part == 'Mentor'
        parts << 'mentor'
      elsif part == 'Speaker'
        parts << 'speaker'
      elsif part == 'Volunteer'
        parts << 'volunteer'
      end
    end
    parts
  end

  # parses the answer JSON based on the type
  # the types choice, choices, and boolean require special handling
  # payment is currently not implemented
  def parse_answer(answer) 
    type = answer['type']
    answers = []
      case type
      when 'choice'
        answers << answer[type].values[0]
      when 'choices'
        answer[type].each do |key, value|
          answers << value unless value == nil
        end
      when 'boolean'
        bool = answer[type] == true ? 1 : 0
        answers << bool
      else 
        answers << answer[type]
      end
    answers.flatten
  end

  def extract_webhook_result(fields, model_field, answers)
    if model_field == "custom"
      determine_webhook_custom(fields, model_field, answers)
    else
      determine_webhook_regular(fields, model_field, answers)
    end
  end

  def determine_webhook_custom(fields, model_field, answers)
    result = []
    determine_webhook_custom_fields(fields).each do |f|
      result << f['title']
      result << get_answer_by_id(answers, f['id'])
    end
    result.flatten
  end

  def determine_webhook_custom_fields(fields)
    custom_fields = []
    fields.each do |f|
      if f['title'].include? 'Q:'
        custom_fields << f
      end
    end
    custom_fields
  end

  def get_answer_by_id(answers, id)
    answer = ''
    answers.each do |answer|
      if answer['field']['id'] == id
        return answer = parse_answer(answer)
      end
    end
    answer
  end

  def determine_webhook_regular(fields, model_field, answers)
    result = []
    fields.each do |f|
      if correct_webhook_field(model_field, f) && !f['title'].include?('Q:')
        result = get_answer_by_id(answers, f['id'])
      end
    end
    result
  end

  def correct_webhook_field(model_field, field) 
    correct_typeform_field = true
    model_field.split('_').each do |f|
      if !split_clean_question(field['title']).include? f
        correct_typeform_field = false
      end
    end
    correct_typeform_field
  end

end
