# (c) Copyright 2021 Ribose Inc.
#

require "spec_helper"

RSpec.describe IEV::Termbase::MarkupConverter do
  subject do
    example = RSpec.current_example
    attributes_str = example.metadata[:string] || example.description
    described_class.new(attributes_str)
  end

  around do |example|
    silence_output_streams { example.run }
  end

  it "returns plain ASCII string unchanged", string: "Abc Def 123" do
    expect(subject.convert).to eq("Abc Def 123")
  end

  it "decodes HTML entities", string: "Abc &lt; 123" do
    expect(subject.convert).to eq("Abc < 123")
  end

  it "does not output any HTML elements",
    string: "<a>Rich <em>text</em></a> with <custom> <other>tags</other>." do
    expect(subject.convert).to include("Rich", "text", "with", "tag")
    expect(subject.convert).not_to include("<a>", "</a>", "<em>", "</em>",
      "<custom>", "</custom>", "<other>", "</other>")
  end

  it "escapes AsciiDoc markup", string: "* What _a_ <b>~text~</b>." do
    pending "Not implemented yet"
    expect(subject.convert).to include('\* What', '\_a\_', '\~text\~')
  end
end
