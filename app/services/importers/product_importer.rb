module Importers
  class ProductImporter < BaseImporter
    private

    def import_row(row)
      name = row["name"].to_s.strip
      slug = row["slug"].to_s.strip
      sku = row["sku"].to_s.strip
      sub_slug = row["subcategory_slug"].to_s.strip
      material = row["material"].to_s.strip
      pieces_count = row["pieces_count"].to_s.strip
      brand = row["brand"].to_s.strip.presence
      is_featured = normalize_bool(row["is_featured"]) 
      is_new = normalize_bool(row["is_new"]) 
      tax_rate = row["tax_rate"].to_s.strip

      raise "name, slug, sku, subcategory_slug, material, pieces_count required" if [name, slug, sku, sub_slug, material, pieces_count].any?(&:blank?)

      subcategory = Subcategory.find_by!(slug: sub_slug)
      product = Product.find_or_initialize_by(slug: slug)
      product.name = name
      product.sku = sku
      product.subcategory = subcategory
      product.material = material
      product.pieces_count = pieces_count.to_i
      product.brand = brand
      product.is_featured = is_featured unless is_featured.nil?
      product.is_new = is_new unless is_new.nil?
      product.tax_rate = (tax_rate.presence || 0).to_f
      if product.new_record?
        product.save!
        @results[:created] += 1
      else
        product.save!
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


