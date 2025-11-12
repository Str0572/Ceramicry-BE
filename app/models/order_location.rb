class OrderLocation < ApplicationRecord
  belongs_to :order
  belongs_to :delivery_agent

  validates :latitude, :longitude, :recorded_at, presence: true

end
