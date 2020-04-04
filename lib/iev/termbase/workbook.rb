module Iev::Termbase
  class Workbook
    def initialize(file:)
      @file = file
    end

    def parse
      if valid_file?(file)
        initialize_workbook(file)
        build_a_hash_object(workbook.sheets.first)
      end
    end

    def build_a_hash_object(book_sheet)
      Iev::Termbase::ConceptCollection.new.tap do |concept_collection|
        book_sheet.simple_rows.each_with_index do |row, index|
          next if index < 1 || row.empty?
          concept_collection.add_term(build_term_object(row))
        end
      end
    end

    def self.parse(file)
      new(file: file).parse
    end

    private

    attr_reader :file, :workbook

    def valid_file?(file)
      !file.nil? && excel_file?(file)
    end

    def excel_file?(file)
      Pathname.new(file).extname == ".xlsx"
    end

    def initialize_workbook(file)
      @workbook = Creek::Book.new(file)
    end

    def build_term_object(row)
      Iev::Termbase::TermBuilder.build_from(row, sheet_key_indices)
    end

    def sheet_key_indices
      @sheet_key_indices ||= workbook.sheets.first.simple_rows.first.invert
    end

  end
end
