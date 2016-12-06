require 'mandrill'

class PeopleController < ApplicationController
  respond_to :json, :html
  include PeopleUtil
  include TypeformWebhook
  include MailchimpUtil
  include TypeformUtil
  include EventsUtil

  def query_by_key_value
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    if event != nil 
      if params[:role] == 'person'
        result = Person.where("#{params[:key]} = ?", params[:value])
        render json: result.map {|person| {:person => person, :participant => person.participant.where(event_id: event.id), 
                                           :volunteer => person.volunteer.where(event_id: event.id), :mentor => person.mentor.where(event_id: event.id)}}
      else
        roles = event.send("#{params[:role]}s")
        result = roles.where("#{params[:key]} = ?", params[:value])
        render json: result.map {|role| {:person => role.person, :role => role}}
      end
    else
      render json: {:errors => 'That event does not exist'}
    end
  end

  def ids
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    role_type = params[:role]
    roles = event.send(role_type.pluralize)
    render json: roles.map { |role| role.id }
  end

  def role
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    model = params[:role].classify.constantize
    role = model.joins(:person).where('people.email = ? AND event_id = ?', params[:email], event.id).first
    if role != nil 
      render json: {:person => role.person, :role => role}
    else
      render json: {:errors => 'That role does not exist'}
    end
  end

  def roles
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    role_type = params[:role]
    roles = event.send(role_type.pluralize)
    render json: roles.map {|role| {:person => role.person, :role => role}}
  end

  def id
    role_type = params[:role]
    model = role_type.classify.constantize
    role = model.find(params[:id])
    render json: {'role': model.find(params[:id]), 'person': role.person}
  end

  def authenticate
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    participant = Participant.joins(:person).where('people.email = ? AND event_id = ?', params[:email], event.id).first
    permanent_pass_correct = false
    temporary_pass_correct = false
    temporary_pass_expired = true
    if participant != nil
      @user = participant.person
      if @user.session_token == params[:session_token]
        session_token = SecureRandom.hex
        @user.session_token = session_token
        @user.save!
        render json: {:success => "Person successfully authenticated", :authentication => "permanent", :session_token => session_token}
        return 
      end
      if @user.password != nil
        unencrypted_password = Password.new(@user.password)
        permanent_pass_correct = unencrypted_password == params[:password]
      elsif @user.temp_password != nil
        unencrypted_temp_password = Password.new(@user.temp_password)
        temporary_pass_correct = unencrypted_temp_password == params[:password]
        if @user.temp_password_datetime != nil
          temp_password_datetime = DateTime.parse(@user.temp_password_datetime.to_s)
          temporary_pass_expired = ((DateTime.now - temp_password_datetime)*24*60).to_i > 60
        end
      else
        render json: {:errors => "Please request a temporary password first!"}
      end
      if temporary_pass_correct
        if !temporary_pass_expired
          render json: {:success => "Please set your new password!", :authentication => "temporary"}
        else
          render json: {:errors => "Your temporary password has expired, please request another one!"}
        end
      elsif permanent_pass_correct
        session_token = SecureRandom.hex
        @user.session_token = session_token
        @user.save!
        render json: {:success => "Person successfully authenticated", :authentication => "permanent", :session_token => session_token}
      elsif @user.password != nil || @user.temp_password != nil
        render json: {:errors => "Your password was invalid, please try again!"}
      end
    else
      render json: {:errors => "Your email could not be found!"}
    end
  end

  def set_password
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    participant = Participant.joins(:person).where('people.email = ? AND event_id = ?', params[:email], event.id).first
    if participant != nil
      @user = participant.person
      session_token = SecureRandom.hex
      @user.session_token = session_token
      @user.password = Password.create(params[:password])
      @user.temp_password = nil
      @user.temp_password_datetime = nil
      @user.save!
      render json: {:success => "New password set successfully", :authentication => "permanent", :session_token => session_token}
    else
      render json: {:errors => "Your email could not be found!"}
    end 
  end

  def reset_password
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    participant = Participant.joins(:person).where('people.email = ? AND event_id = ?', params[:email], event.id).first
    if participant != nil 
      @user = participant.person
      send_password(@user, params[:email], false)
      render json: {:success => "Temporary password successfully sent!"}
    else
      render json: {:errors => "Your email could not be found!"}
    end
  end

  def update_role_external
    role_type = params[:role]
    model = role_type.classify.constantize
    role = model.find(params[:id])
    role.update_attributes(role_params(params[:role], params))
    render json: {'role': role}
  end
  
  # push means the request came from a webhook and the client should be updated automatically
  def update_role_push
    params_hash = parse_push_json(params)
    if params_hash.size == 0
      render json: {:errors => "No form route provided"}
    end
    update_role_logic(params_hash, true)
  end

  def receive_role_push
    params_hash = parse_push_json(params)
    if params_hash.size == 0
      render json: {:errors => "No form route provided"}
    end
    receive_role_logic(params_hash, true)
  end

  def receive_role
    receive_role_logic(params)
  end

  def update_role
    update_role_logic(params)
  end

  # shows all info given a season, year, event_type grouped by person and alphabetically
  # each person has info from the person model as well as the role's models
  def event
    semester = Semester.where('season = ? AND year = ?', Semester.seasons[params[:season]], params[:year]).first
    event = semester.events.where('event_type = ?', Event.event_types[params[:event_type]]).first
    roles = []
    Person.roles.keys.each do |role_type|
      model = role_type.classify.constantize
      roles += model.where('event_id = ?', event.id).map{|role| 
        {
          :person_id => role.person_id, 
          :role => role.attributes.except('id', 'person_id', 'slack_id', 'created_at', 'updated_at'),
          :role_type => role_type
        } 
      }
    end
    output = roles.group_by{|x| x[:person_id]}.map{|k,v| 
      { :person => Person.find(k).attributes.slice('first_name', 'last_name', 'phone', 'email', 'gender', 'ethnicity', 'dietary_restrictions'),
        :roles => v.map{|ele| { role_with_status(ele[:role], ele[:role_type]) => ele[:role] } }
      }
    }
    render json: output.sort_by {|v| v[:person]['first_name'].downcase}
  end

end
