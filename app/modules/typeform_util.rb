module TypeformUtil

  # determines the form's route from the hidden_field
  # see the README for an explanation of typeform routes
  def get_webhook_route(form_response)
    route = ''
    form_response[:hidden].each do |key, value|
      split_hidden = key.split('_')
      has_route = split_hidden.include? 'route'
      has_three_parts = split_hidden.length == 3
      if has_route && has_three_parts
        route = split_hidden
      end
    end
    route
  end

  # detect whether the result should be an array or not
  # if the default value is nil, 0 (for integer), or '' (for string) 
  # then it should only be the first element of the result array
  def handle_results_array_by_field(model, field, result)
    if model.new[field] == nil || model.new[field] == 0 || model.new[field] == ''
      result = result[0]
    end
    result
  end

  def get_data_route(questions)
    route = ''
    questions.each do |question|
      question_field = question['question']
      split_question = question_field.split('_')
      has_route = split_question.include? 'route'
      has_three_parts = split_question.length == 3
        if has_route && has_three_parts
          route = split_question
        end
    end
    route
  end

  def replace_email_if_necessary(hidden_email, person)
    if hidden_email != nil && hidden_email != ''
      person[:email] = hidden_email
    end
  end

  # removes all non-alphanumeric/space characters
  def split_clean_question(question)
    question.downcase.gsub(/[^a-z0-9\s]/i, '').split(' ') 
  end

  def no_route_error(fid)
    puts fid
    puts "The typeform with form id #{fid} has no route"
  end

  def valid_result(result, field)
    unallowed_fields = ['id', 'updated_at', 'created_at', 'form_id']
    result != nil && result != '' && field != '' && result.size > 0 && !unallowed_fields.include?(field)
  end

  def remove_all_submission_history
    Person.all.each do |person|
      person.form_id = []
      person.submit_date = []
      person.save!
    end
  end

end