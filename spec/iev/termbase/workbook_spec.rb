require "spec_helper"

RSpec.describe Iev::Termbase::Workbook do
  describe ".parse" do
    it "parses to xls file to workbook" do
      workbook = Iev::Termbase::Workbook.parse(sample_file)

      first_term = workbook.to_hash[1030101]
      kor_source = first_term["kor"]["authoritative_source"]

      expect(workbook.size).to eq(2)
      expect(first_term["eng"]["id"]).to eq(1030101)
      expect(kor_source["clause"]).to eq("103-08-10")
      expect(kor_source["link"]).to eq("https://webstore.iec.ch/publication/161")
    end
  end

  def sample_file
    Iev.root_path.join("spec", "fixtures", "sample-file.xlsx")
  end
end
