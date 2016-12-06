require_relative '../app/modules/typeform_data'
require_relative '../app/modules/typeform_util'

# this class retrieves all results from typeform and stores them 
# in a person_hash to maintains the order in which updates are applied
# to restore the true state of the database

class DatabaseTester
	include TypeformUtil
	include TypeformData

  def generate_person_hash(events)
    person_hash = {}
    events.each do |event|
      event.form_ids.each_with_index do |form_id, index|
        # make sure you get all results, the data API caps at 1000 so you have to change offset
        form_object = ActiveSupport::JSON.decode(HTTParty.get(data_api_url(form_id)).body)
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
          return false
        end
        role = route[2]
        model = role.classify.constantize
        role_question_field_hash = question_id_field_hash(form_object['questions'], model)
        person_question_field_hash = question_id_field_hash(form_object['questions'], Person)

        responses.each do |r|
          # processes a person's info and add to a hash that accumulates state for every field
          email = determine_email(person_question_field_hash, r)
          if email != nil 
            email = email.strip.downcase
            person = Person.where(email: email).first
            if person != nil 
              process_person(email, person, role, event, r, person_hash, role_question_field_hash, 
            							 person_question_field_hash, form_id, r['metadata']['date_submit'])
            else
              puts "Email #{email} should exist"
            end
          end
        end
      end
    end
    person_hash
  end

  def determine_email(person_question_field_hash, r)
    email = r['hidden']['email']
    person_question_field_hash.each do |k, v|
      if v == 'email' && (email == nil || email == '')
        email = r['answers'][k]
      end
    end
    email
  end

  def process_person(email, person, role, event, r, person_hash, role_field_hash, 
  				 person_field_hash, form_id, submit_date)
    temp_person_hash = {}
    r['answers'].each do |key, value|
      if value != nil && value != ''
        attribute = ''
        attribute_value = ''
        # determines whether attribute belongs in the role model or the person model
        if role_field_hash.key? key
          role_object = person.send(role).where(event_id: event.id).first
          if role_object == nil
            puts "The role #{role} for #{email} should exist"
          end
          attribute_value = value
          attribute = role_field_hash[key]
        elsif person_field_hash.key? key
          attribute_value = value
          attribute = person_field_hash[key]
        end
        if key.include? 'date'
          attribute_value = DateTime.parse(attribute_value)
        end
        # adds attribute to the temp_person_hash and keeps accumulating
        # don't add http:// attributes because they should be blank
        if attribute != '' && attribute_value != '' && attribute_value != 'http://'
          add_to_temp_person_hash(temp_person_hash, attribute, attribute_value)
        end
      end
    end
    # adds temp_person_hash to global hash by concatenating answers as an array
    temp_person_hash.each do |attribute, answers_array|
      add_to_person_hash(person_hash, answers_array, person.email, role, attribute, event)
    end
    add_to_person_hash_submissions(person_hash, person.email, form_id, submit_date)
  end

  def add_to_person_hash_submissions(person_hash, email, form_id, submit_date)
    if !person_hash.key? email
      person_hash[email] = {}
    end
    if !person_hash[email].key? 'form_id'
      person_hash[email]['form_id'] = []
    end
    if !person_hash[email].key? 'submit_date'
      person_hash[email]['submit_date'] = []
    end
      person_hash[email]['form_id'] << form_id
      person_hash[email]['submit_date'] << submit_date
  end

  # add to the person_hash, with the primary key being the email,
  # the secondary key being the role + attribute + event id (unless it's an update to the Person model)
  def add_to_person_hash(person_hash, answers_array, email, role, attribute, event)
  # currently emails cannot be modified through typeform and are ignored
    if attribute == "email"
      return
    end
    attribute_key = "#{attribute} #{role} #{event.id}"
    if Person.attribute_names.include? attribute
      attribute_key = "#{attribute} person"
    end
    if !person_hash.key? email
      person_hash[email] = {}
    end
    if !person_hash[email].key? attribute_key
      person_hash[email][attribute_key] = []
    end
    person_hash[email][attribute_key] << answers_array
  end

  def add_to_temp_person_hash(temp_person_hash, attribute, value)
    if !temp_person_hash.key? attribute
      temp_person_hash[attribute] = []
    end
    temp_person_hash[attribute] << value.to_s.strip.downcase
  end

  # valides the property of every person's attribute and see's
  # if everything is present/updated on the database
  def validate_person_hash(person_hash, email, attribute_hash)
    truth_array = []
    person = Person.where(email: email).first
    attribute_hash.each do |attribute_key, arrays|
      # the form_id branch checks both the submit date and form id
      if attribute_key.include?('submit_date')
        next
      end
      if attribute_key.include?('form_id')
        truth_array << validate_submission_form_arrays(person_hash, person)
      else
        truth_array << validate_attribute_for_person(attribute_key, person, arrays)
      end
    end
    !truth_array.include? false
  end	

  # validates if the submission history is the same on the database and typeform
  def validate_submission_form_arrays(person_hash, person)
    valid_arrays = true
    form_id_typeform_array = person_hash[person.email]['form_id']
    submit_date_typeform_array = map_datetime_parse_array(person_hash[person.email]['submit_date'])

    form_id_database_array = person.send('form_id')
    submit_date_database_array = map_datetime_parse_array(person.send('submit_date'))

    # sorting the typeform array by submit_date because that's how
    # it'll appear in the database
    typeform_array = form_id_typeform_array.each_with_index.map { |x, i| 
      {'form_id': x, 'submit_date': submit_date_typeform_array[i]} 
    }

    typeform_array.sort! {|x,y| x[:submit_date] <=> y[:submit_date] }

    form_id_typeform_array = typeform_array.map { |x| x[:form_id] } 
    submit_date_typeform_array = typeform_array.map { |x| x[:submit_date] } 

    database_array = form_id_database_array.each_with_index.map { |x, i| 
      {'form_id': x, 'submit_date': submit_date_database_array[i]} 
    }

    database_array.sort! {|x,y| x[:submit_date] <=> y[:submit_date] }

    form_id_database_array = database_array.map { |x| x[:form_id] } 
    submit_date_database_array = database_array.map { |x| x[:submit_date] } 

    valid_submit = validate_arrays(submit_date_typeform_array, submit_date_database_array, person)
    valid_form = validate_arrays(form_id_typeform_array, form_id_database_array, person)
    valid_submit && valid_form
  end

  def map_datetime_parse_array(array)
    array.map{|date| DateTime.parse(date)}
  end

  # compares arrays by length then iterating one at a time
  def validate_arrays(typeform_array, database_array, person)
    if database_array.size != typeform_array.size
      print_submission_arrays_info(typeform_array, database_array, person)
      return false
    end
    database_array.each_with_index do |element, index|
      if element != typeform_array[index]
        print_submission_arrays_info(typeform_array, database_array, person)
        return false
      end
    end
    true
  end

  def print_submission_arrays_info(typeform_array, database_array, person)
    puts ""
    puts "#{person.email} has incorrect values in their submission history"
    puts "The value from the database is #{database_array.join(", ")}"
    puts "The value from the typeform is #{typeform_array.join(", ")}"
  end

  def validate_attribute_for_person(attribute_key, person, arrays)
    attribute_split = attribute_key.split(" ")
    attribute = attribute_split[0]
    role = attribute_split[1]
    model = role.classify.constantize
    # determines whether an attribute is for the person or role model
    # and compares the last array in the person_hash (the most updated version from Typeform)
    # to the array formed by reading from the database
    if Person.attribute_names.include? attribute
      database_attribute_array = clean_attribute_array([person.send(attribute.to_s)])
      database_attribute_array = map_attribute_array_if_datetime(database_attribute_array, attribute, model)
    elsif model.attribute_names.include? attribute
      event = Event.find(attribute_split[2])
      role_object = person.send(role).where(event_id: event.id).first
      database_attribute_array = clean_attribute_array([role_object.send(attribute.to_s)])
      database_attribute_array = map_attribute_array_if_datetime(database_attribute_array, attribute, model)
    end
    arrays.last.each do |attribute_value|
      # if it's a file, the two APIs have different formats, so it automatically returns true
      # https://admin.typeform.com/form/results/file/download/pzb8zj/...
      # https://api.typeform.com/v0/form/pzb8zj/fields/29519912/blob/...
      if attribute == 'resume' || 'travel' && database_attribute_array.count > 0
        return true
      end
      # if an attribute that requires an integer does not get one from typeform, automatically pass this attribute
      if model.columns_hash[attribute].type == :integer
        if attribute_value.is_a?(Array)
          attribute_value.each do |value|
            next unless value.is_a?(Integer)
          end
        else
          next unless attribute_value.is_a?(Integer)
        end
      end
      if !database_attribute_array.include? attribute_value
        print_attribute_info(person, attribute, database_attribute_array, arrays, role)
        return false
      end
    end
    true
  end

  def print_attribute_info(person, attribute, database_attribute_array, arrays, role)
    puts ""
    puts "#{person.email} has incorrect values at attribute #{attribute} and role #{role}"
    puts "The value from the database is #{database_attribute_array.join(", ")}"
    puts "The value from the typeform is #{arrays.last.join(", ")}"
    puts "The history of typeform submissions for this attribute is:"
    arrays.each_with_index do |array, index|
      puts "#{index}: #{array.join(", ")}"
    end
  end

  def clean_attribute_array(array)
    array.flatten.select {|value| value != nil}.map {|value| value.to_s.strip.downcase.gsub('\n', '')}
  end

  def map_attribute_array_if_datetime(database_attribute_array, attribute, model)
    attribute_array = database_attribute_array
    if model.columns_hash[attribute].type == :datetime 
      attribute_array = database_attribute_array.map {|value| DateTime.parse(value)}
    end
    attribute_array
  end

  def question_contains_attribute(question_array, attribute)
    correct_question = true
    attribute.split('_').each do |a|
      if !question_array.include? a
        correct_question = false
      end
    end
    correct_question
  end

  # generates a hash mapping question_id (used to find answers) to the field it belongs 
  def question_id_field_hash(questions, model)
    hash = {}
    questions.each do |q|
      question_array = q['question'].parameterize.downcase.underscore.split('_')
        if q['question'].split(' ').include? 'Q:'
          hash[q['id']] = 'custom'
        elsif !q['id'].include? 'hidden'
          model.attribute_names.each do |attribute|
          # may be possible for question id to contain more than one attribute, 
          # the attribute for that question_id in the hash will be overwritten 
          if question_contains_attribute(question_array, attribute)
            hash[q['id']] = attribute
          end
        end
      end
    end
  hash
  end

end