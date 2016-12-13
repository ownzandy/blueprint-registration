require 'logger'
require 'mailchimp_util'

module PeopleUtil
  include MailchimpUtil

  # updates a person's information in its role and person model 
  # email is the primary identifier and we must be sure the cleaned version is in the database
  def update_role_logic(params, push=false)
    email = clean_email(params[:person][:email])
    event = Event.where("'#{params[:form_id]}' = ANY (form_ids)").first
    model = params[:role].classify.constantize
    role = model.joins(:person).where('people.email = ? AND event_id = ?', email, event.id).first
    if role != nil
      role_params = params[params[:role].to_sym]
      role_hash = role_params
      if !role_params.is_a? Hash 
        role_hash = role_params.to_unsafe_h
      end
      if role_hash.size > 0 
        # update attributes if parameters for the role have been provided
        role.update_attributes(role_params(params[:role], params))
        # update status if participant and attending has become true
        if params[:role] == 'participant' && role_params[:attending] == 1
          role.status = 3
        end
      end
      append_to_submission_history(role, params)
      # updates attributes for the person (email is always provided)
      role.person.update_attributes(person_params(params))
      role.person.email = email
      # save person and role
      role.person.save!
      role.save!
      if push 
        trigger_push
      end
      begin
        render json: {:person => role.person, role_sym(params[:role]) => role}
      rescue
        render json: {:errors => 'Person and role could not be converted to JSON'}
      end
    else
      render json: {:errors => 'That role does not exist'}
    end
  end

  # makes new role in database given information and form_id and adds to mailchimp list
  # makes new person as well if he/she doesn't exist in the database
  # updates existing person if he/she is in the database already (the last submission is taken)
  # event is identified by form_id so forms cannot be re-used among events
  def receive_role_logic(params, push=false)
    email = clean_email(params[:person][:email])
    event = Event.where("'#{params[:form_id]}' = ANY (form_ids)").first
    roles = params[:parts]
    roles.each do |role_name|
      # creates new role if the role is not in the database
      existing_person = person_exists(email)
      if existing_person == nil
        # creates new person if person is not in the database
        person = Person.new(person_params(params))
        person.email = email
      else
        # updates the person if the person is in the database
        person = existing_person
        person.update_attributes(person_params(params))
      end

      role = person.send(role_name).where(event_id: event.id).first
      if role == nil
        model = role_name.classify.constantize
        begin 
          role = model.new(role_params(role_name, params))
        rescue
          role = model.new
        end
        role.event = event
      else
        role.update_attributes(role_params(role_name, params))
      end

      role.person = person
      # save person and role
      role.person.save!
      role.save!
      # determines mailchimp_id by role and adds to list 
      # doesn't matter if he/she already exists
      mailchimp_id = event.mailchimp_ids[Person.roles[role_name]].split(',')[0]
      add_to_mailchimp_list(event, person, email, mailchimp_id)
    end

    begin
      render json: {:person => person}
    rescue
      render json: {:errors => 'Person and role could not be converted to JSON'}
    end

  end

  def role_sym(role)
    role.parameterize.underscore.to_sym 
  end

  def append_to_submission_history(role, params)
    role.person.submit_date << params[:submit_date]
    role.person.form_id << params[:form_id]
  end

  # triggers push to client when roles have been added
  def trigger_push
    Pusher.trigger('update_channel', 'trigger_update', {
      message: 'fetch roles'
    })
  end

  def role_with_status(role, type)
    add_on = ''
    if role.key? 'status'
    add_on = ' ' + role['status']
    end
    type + add_on
  end

  def clean_email(email) 
    return email.strip.downcase
  end

  def person_exists(email)
    Person.where('email = ?', email).first
  end

  # parameters dynamically determine by the person's role
  # must be updated every time schema changes
  def role_params(role, params)
    params = prepare_hash_as_params(params)
    case Person.roles[role]
    when 0
      return params.require(:participant).permit(:status, :school, :website, :resume, :attending, :github,
    																				 :portfolio, :graduation_year, :major, :over_eighteen, :slack_id, :track,
                                             :travel, :skills => [], :custom => [], :benefits => [], :part => [])
    when 1
      return params.require(:speaker).permit(:slack_id, :role, :department, :organization, :position, :date => [], :topic => [])
    when 2
      return params.require(:judge).permit(:slack_id, :skills => [])
    when 3
      return params.require(:mentor).permit(:status, :slack_id, :track, :role, :department, :organization, :position, :skills => [], :benefits => [])
    when 4
      return params.require(:volunteer).permit(:status, :slack_id, :hours, :times => [], :custom => [], :benefits => [])
    when 5
      return params.require(:organizer).permit(:slack_id)
    else 
      return {}
    end
  end

  def person_params(params)
    params = prepare_hash_as_params(params)
    params.require(:person).permit(:first_name, :gender, :last_name, :email, :phone, :slack_id, :ethnicity, :emergency_contacts, :size, :dietary_restrictions => [])
  end

  def prepare_hash_as_params(params)
    if !params.is_a? Hash
      params = ActionController::Parameters.new(params.to_unsafe_h)
    else
      params = ActionController::Parameters.new(params)
    end
  end

end