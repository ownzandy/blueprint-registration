class Semester < ActiveRecord::Base
  has_many :events
  enum season: [ :spring, :fall]
end
