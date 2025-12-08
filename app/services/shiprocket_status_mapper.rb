class ShiprocketStatusMapper
  class << self
    def from_webhook(event_id, status_text)
      event_id = event_id.to_i if event_id
      text     = status_text.to_s.downcase

      case event_id
      when 6   then 'shipped'
      when 12  then 'out_for_delivery'
      when 8   then 'delivered'
      when 9, 10 then 'returned'
      else
        from_text(text)
      end
    end

    def from_tracking(tracking_data, status_text)
      event          = tracking_data.dig('tracking_data', 'shipment_track')&.last
      sr_status_code = event&.dig('status_code')
      text           = status_text.to_s.downcase

      case sr_status_code
      when 6   then 'shipped'
      when 12  then 'out_for_delivery'
      when 8   then 'delivered'
      when 9, 10 then 'returned'
      else
        from_text(text)
      end
    end

    private

    def from_text(text)
      return 'delivered'        if text.include?('delivered')
      return 'out_for_delivery' if text.include?('out for delivery')
      return 'shipped'          if text.include?('in transit') || text.include?('picked')
      return 'returned'         if text.include?('rto')
      nil
    end
  end
end
