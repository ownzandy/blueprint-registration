class Judge < ApplicationRecord
  belongs_to :event
  belongs_to :person
end
