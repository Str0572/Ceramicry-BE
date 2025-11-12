module Importers
  class CategoryImporter < BaseImporter
    private

    def import_row(row)
      name = row["name"].to_s.strip
      slug = row["slug"].to_s.strip
      description = row["description"].to_s.strip.presence
      raise "name is required" if name.blank?
      raise "slug is required" if slug.blank?

      category = Category.find_or_initialize_by(slug: slug)
      category.name = name
      category.description = description
      if category.new_record?
        category.save!
        @results[:created] += 1
      else
        category.save!
        @results[:updated] += 1
      end
    end
  end
end


