require "spec_helper"

RSpec.describe "IEV Termbase" do
  describe "xlsx2yaml" do
    it "parses xlsx document to yaml" do
      command = %W(xlsx2yaml #{sample_xlsx_file} -o ./tmp --no-write)
      output = capture_stdout { Iev::Termbase::Cli.start(command) }

      expect(output).to include("ger:")
      expect(output).to include("103-01-01:")
      expect(output).to include("term: 범함수")
    end
  end

  def sample_xlsx_file
    Iev.root_path.join("spec", "fixtures", "sample-file.xlsx")
  end
end
