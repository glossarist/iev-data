require "spec_helper"

RSpec.describe "IEV Termbase" do
  let(:sample_xlsx_file) { fixture_path("sample-file.xlsx") }

  describe "xlsx2yaml" do
    it "exports YAMLs from given XLSX document" do
      Dir.mktmpdir("iev-test") do |dir|
        command = %W(xlsx2yaml #{sample_xlsx_file} -o #{dir})
        silence_output_streams { IEV::Termbase::CLI.start(command) }

        concepts_dir = File.join(dir, "concepts")
        expect(concepts_dir).to satisfy { |p| File.directory? p }
        expect(Dir["#{concepts_dir}/concept-*.yaml"]).not_to be_empty

        concept1 = File.read(File.join(concepts_dir, "concept-103-01-01.yaml"))
        concept2 = File.read(File.join(concepts_dir, "concept-103-01-02.yaml"))

        expect(concept1).to include("termid: 103-01-01")
        expect(concept1).to include("term: function")
        expect(concept1).to include("deu:")
        expect(concept1).to include("designation: function")
        expect(concept1).to match(/related:\s*- type: supersedes/)

        expect(concept2).to include("termid: 103-01-02")
        expect(concept2).to include("term: functional")
        expect(concept2).to include("deu:")
        expect(concept2).to include("designation: 범함수")
      end
    end
  end
end
