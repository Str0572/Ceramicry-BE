module Importers
  class VariantImporter < BaseImporter
    private

    def import_row(row)
      product_sku = row["product_sku"].to_s.strip
      sku = row["sku"].to_s.strip
      size = row["size"].to_s.strip.presence
      color = row["color"].to_s.strip.presence
      price = row["price"].to_s.strip
      original_price = row["original_price"].to_s.strip
      discount_percentage = row["discount_percentage"].to_s.strip
      stock_quantity = row["stock_quantity"].to_s.strip

      raise "product_sku, sku, price, stock_quantity required" if [product_sku, sku, price, stock_quantity].any?(&:blank?)

      product = Product.find_by!(sku: product_sku)
      variant = Variant.find_or_initialize_by(sku: sku)
      variant.product = product
      variant.size = size
      variant.color = color
      variant.price = price.to_f
      variant.original_price = original_price.present? ? original_price.to_f : nil
      variant.discount_percentage = discount_percentage.present? ? discount_percentage.to_i : 0
      variant.stock_quantity = stock_quantity.to_i
      if variant.new_record?
        variant.save!
        @results[:created] += 1
      else
        variant.save!
        @results[:updated] += 1
      end
    end
  end
end


