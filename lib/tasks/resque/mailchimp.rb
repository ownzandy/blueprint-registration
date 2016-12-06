class Mailchimp

  def self.perform(method)
    self.new.send(method)
  end

  def sync
    Event.where(active: 1).each do |event|
      batch_sync(event)
    end
  end

  def batch_sync(event)
    operations = []
    mailchimp_ids = event.mailchimp_ids[0].split(',')
    event.participants.each do |participant|
      if participant.attending == 1 && participant.status = 'accepted'
        participant.status = 'confirmed'
        participant.save!
      end
      person = participant.person
      mailchimp_ids.each_with_index do |id, index|
        if index == Participant.statuses[participant.status]
          operations.append({
            :method => "PUT",
            :path => "/lists/#{id}/members/#{subscriber_hash(person.email)}",
            :body => {
              :email_address => person.email,
              :status => "subscribed",
              :merge_fields => { :FNAME => person.first_name,
                                 :LNAME => person.last_name}
            }.to_json
          })
        else
          operations.append({
            :method => "PUT",
            :path => "/lists/#{id}/members/#{subscriber_hash(person.email)}",
            :body => {
              :email_address => person.email,
              :status => "unsubscribed",
              :merge_fields => { :FNAME => person.first_name,
                                 :LNAME => person.last_name}
            }.to_json
          })
        end
      end
    end
    puts api.batches.create(body: {:operations => operations})
  end

  def api
    Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
  end

  def subscriber_hash(email)
    Digest::MD5.hexdigest(email)
  end

end