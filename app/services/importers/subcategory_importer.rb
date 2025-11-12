module Importers
  class SubcategoryImporter < BaseImporter
    private

    def import_row(row)
      name = row["name"].to_s.strip
      slug = row["slug"].to_s.strip
      category_slug = row["category_slug"].to_s.strip
      description = row["description"].to_s.strip.presence
      raise "name is required" if name.blank?
      raise "slug is required" if slug.blank?
      raise "category_slug is required" if category_slug.blank?

      category = Category.find_by!(slug: category_slug)
      subcategory = Subcategory.find_or_initialize_by(slug: slug)
      subcategory.name = name
      subcategory.description = description
      subcategory.category = category
      if subcategory.new_record?
        subcategory.save!
        @results[:created] += 1
      else
        subcategory.save!
        @results[:updated] += 1
      end
    end
  end
end


