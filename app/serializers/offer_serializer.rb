class OfferSerializer < ActiveModel::Serializer
  attributes :id, :code, :discount, :discount_type, :min_order, :description, :active, :expires_at, :usage_limit, :remaining_uses

  def remaining_uses
    return nil if object.usage_limit.zero?
    object.usage_limit - object.offer_usages.count
  end
end
