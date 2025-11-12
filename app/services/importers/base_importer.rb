require 'csv'

module Importers
  class BaseImporter
    attr_reader :file, :results, :errors

    def initialize(file)
      @file = file
      @results = { created: 0, updated: 0, failed: 0 }
      @errors = []
    end

    def call
      rows = parse_rows
      ActiveRecord::Base.transaction do
        rows.each_with_index do |row, index|
          begin
            import_row(row)
          rescue => e
            @results[:failed] += 1
            @errors << "Row #{index + 2}: #{e.message}"
          end
        end
      end
      self
    end

    private

    def parse_rows
      if xlsx?(file)
        xlsx_to_rows(file)
      else
        csv_to_rows(file)
      end
    end

    def csv_to_rows(uploaded_file)
      CSV.read(uploaded_file.path, headers: true).map { |r| r.to_h.transform_keys { |k| k.to_s.strip.downcase } }
    end

    def xlsx_to_rows(uploaded_file)
      xlsx = Roo::Spreadsheet.open(uploaded_file.path)
      sheet = xlsx.sheet(0)
      headers = sheet.row(1).map { |h| h.to_s.strip.downcase }
      (2..sheet.last_row).map do |i|
        row = sheet.row(i)
        headers.zip(row).to_h.transform_keys { |k| k.to_s.strip.downcase }
      end
    end

    def xlsx?(uploaded_file)
      File.extname(uploaded_file.original_filename).downcase.in?([".xlsx", ".xls"]) rescue false
    end

    def import_row(_row)
      raise NotImplementedError
    end
  end
end


