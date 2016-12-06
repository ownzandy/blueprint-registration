class Sponsor < ApplicationRecord
  belongs_to :event
  has_one :organization
  enum sponsorship_tier: [ :tier_I, :tier_II, :tier_III, :tier_IV, :tier_V]
end
