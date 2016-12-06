class Mentor < ApplicationRecord
  belongs_to :event
  belongs_to :person
  enum status: [:registered, :confirmed, :attended]
end
