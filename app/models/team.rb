class Team < ApplicationRecord
  belongs_to :event
  has_many :participants
  has_many :projects
end
