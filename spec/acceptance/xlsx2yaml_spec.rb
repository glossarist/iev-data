require "spec_helper"

RSpec.describe "IEV Termbase" do
  let(:sample_xlsx_file) { fixture_path("sample-file.xlsx") }

  describe "xlsx2yaml" do
    it "parses xlsx document to yaml" do
      command = %W(xlsx2yaml #{sample_xlsx_file} -o ./tmp --no-write)
      output, * = capture_output_streams { Iev::Termbase::Cli.start(command) }

      expect(output).to include("deu:")
      expect(output).to include("103-01-01:")
      expect(output).to include("designation: 범함수")
    end
  end
end
