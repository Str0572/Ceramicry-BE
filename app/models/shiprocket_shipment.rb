class ShiprocketShipment < ApplicationRecord
  belongs_to :order

  validates :order, presence: true
  validates :awb_code, presence: true, uniqueness: true
  validates :sr_order_id, :sr_shipment_id, presence: true

  scope :active, -> { where.not(sr_shipment_id: nil) }

  def tracking_url
    return read_attribute(:tracking_url) if self[:tracking_url].present?
    return nil if awb_code.blank?
    "https://track.shiprocket.in/tracking/#{awb_code}"
  end
end
