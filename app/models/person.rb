class Person < ApplicationRecord
  belongs_to :organization
  has_many :participant
  has_many :speaker
  has_many :judge
  has_many :mentor
  has_many :volunteer
  has_many :organizer
  enum roles: [:participant, :speaker, :judge, :mentor, :volunteer, :organizer]

end