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

  example "<i>italics</i>" do
    expect(subject.convert).to eq("__italics__")
  end

  example "<i>italics with implicit end" do
    expect(subject.convert).to eq("__italics with implicit end__")
  end

  example "<b>bold</b>" do
    expect(subject.convert).to eq("**bold**")
  end

  example "<b>bold with implicit end" do
    expect(subject.convert).to eq("**bold with implicit end**")
  end

  example "<sub>subscript</sub>" do
    expect(subject.convert).to eq("~~subscript~~")
  end

  example "<sub>subscript with implicit end" do
    expect(subject.convert).to eq("~~subscript with implicit end~~")
  end

  example "<sup>superscript</sup>" do
    expect(subject.convert).to eq("^^superscript^^")
  end

  example "<sup>superscript with implicit end" do
    expect(subject.convert).to eq("^^superscript with implicit end^^")
  end

  example "<math><mi>a</mi><mo>+</mo><mn>3</mn></math>" do
    expect(subject.convert).to eq("stem:[a + 3]")
  end

  example "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">" +
    "<mi>a</mi><mo>+</mo><mn>3</mn></math>" do
    expect(subject.convert).to eq("stem:[a + 3]")
  end

  example "<p>Text with</p><p>two paragraphs.</p>" do
    pending "Strip new lines from the beginning"
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text with

      two paragraphs.
    ASCIIDOC
    expect(subject.convert).to eq("")
  end

  example "Text with<p>paragraphs<p>but without closing tags." do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text with

      paragraphs

      but without closing tags.
    ASCIIDOC
  end

  example "Excessing<p><p>paragraphs<p>are ignored.<p><p><p>" do
    pending "Not implemented yet"
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Excessing

      paragraphs

      are ignored.
    ASCIIDOC
  end

  example "Text<br>with <br />line breaks." do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text+
      with +
      line breaks.
    ASCIIDOC
  end

  example "complicated example" do
    pending "Some tweaks are still needed"

    src = <<~HTML
      This text <b>consists of</b> rich text with <i>some elements being
      implicitly-<sup>ended</i>.
      <p>It also has paragraphs,<br>line breaks &amp; entities,
      including &rarr;Unicode&larr; ones.
      <p>And finally, a <a href="http://example.com">link</a>!
    HTML

    expectation = <<~ASCIIDOC
      This text **consists of** rich text with __some elements being
      implicitly-^^ended^^__.

      It also has paragraphs,+
      line breaks & entities,
      including &rarr;Unicode&larr; ones.

      And finally, a http://example.com[link]!
    ASCIIDOC

    expect(described_class.new(src).convert).to eq(expectation)
  end

end
