module Importers
  class OfferImporter < BaseImporter
    private

    def import_row(row)
      code = row["code"].to_s.strip
      discount = row["discount"].to_s.strip
      discount_type = row["discount_type"].to_s.strip.presence || 'percentage'
      min_order = row["min_order"].to_s.strip
      description = row["description"].to_s.strip.presence
      active = normalize_bool(row["active"]) 
      expires_at = row["expires_at"].to_s.strip.presence
      usage_limit = row["usage_limit"].to_s.strip

      raise "code and discount required" if [code, discount].any?(&:blank?)

      offer = Offer.find_or_initialize_by(code: code)
      offer.discount = discount.to_f
      offer.discount_type = discount_type
      offer.min_order = (min_order.presence || 0).to_f
      offer.description = description
      offer.active = active.nil? ? true : active
      offer.expires_at = expires_at.present? ? Time.zone.parse(expires_at) : nil
      offer.usage_limit = (usage_limit.presence || 0).to_i

      if offer.new_record?
        offer.save!
        @results[:created] += 1
      else
        offer.save!
        @results[:updated] += 1
      end
    end

    def normalize_bool(value)
      return nil if value.nil?
      v = value.to_s.strip.downcase
      return true if v.in?(["true", "1", "yes", "y"])
      return false if v.in?(["false", "0", "no", "n"])
      nil
    end
  end
end


