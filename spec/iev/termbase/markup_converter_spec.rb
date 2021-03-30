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

  it "decodes HTML entities", string: "Text with &aelig;ntity" do
    expect(subject.convert).to eq("Text with æntity")
  end

  it "does not output any HTML elements",
    string: "<a>Rich <em>text</em></a> with <custom> <other>tags</other>." do
    expect(subject.convert).to include("Rich", "text", "with", "tag")
    expect(subject.convert).not_to include("<a>", "</a>", "<em>", "</em>",
      "<custom>", "</custom>", "<other>", "</other>")
  end

  it "escapes AsciiDoc markup", string: "* What _a_ <b>~text~</b>." do
    pending "Not working yet for some reason"
    expect(subject.convert).to include('\* What', '\_a\_', '\~text\~')
  end

  example "<i>italics</i>" do
    expect(subject.convert).to eq("_italics_")
  end

  example "<i>italics with implicit end" do
    expect(subject.convert).to eq("_italics with implicit end_")
  end

  example "<b>bold</b>" do
    expect(subject.convert).to eq("*bold*")
  end

  example "<b>bold with implicit end" do
    expect(subject.convert).to eq("*bold with implicit end*")
  end

  example "<sub>subscript</sub>" do
    expect(subject.convert).to eq("~subscript~")
  end

  example "<sub>subscript with implicit end" do
    expect(subject.convert).to eq("~subscript with implicit end~")
  end

  example "<sup>superscript</sup>" do
    expect(subject.convert).to eq("^superscript^")
  end

  example "<sup>superscript with implicit end" do
    expect(subject.convert).to eq("^superscript with implicit end^")
  end

  example "<math><mi>a</mi><mo>+</mo><mn>3</mn></math>" do
    expect(subject.convert).to eq("stem:[a + 3]")
  end

  example "<math xmlns=\"http://www.w3.org/1998/Math/MathML\">" +
    "<mi>a</mi><mo>+</mo><mn>3</mn></math>" do
    expect(subject.convert).to eq("stem:[a + 3]")
  end

  example "<p>Text with</p><p>two paragraphs.</p>" do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text with

      two paragraphs.
    ASCIIDOC
  end

  example "Text with<p>paragraphs<p>but without closing tags." do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text with

      paragraphs

      but without closing tags.
    ASCIIDOC
  end

  example "Excessing<p><p>paragraphs<p>are ignored.<p><p><p>" do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Excessing

      paragraphs

      are ignored.
    ASCIIDOC
  end

  example "Text<br>with <br />line breaks." do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      Text +
      with +
      line breaks.
    ASCIIDOC
  end

  example "Arbitrary <a href=\"http://example.test\">link</a>." do
    expect(subject.convert).to eq("Arbitrary http://example.test[link].")
  end

  example "IEV link to <a href=IEV102-03-23>magnitude</a> concept." do
    expect(subject.convert).to eq(<<~ASCIIDOC.chomp)
      IEV link to {{magnitude, IEV:102-03-23}} concept.
    ASCIIDOC
  end

  example "<ol><li>One<li>Two<li>Three</ol>" do
    expect(subject.convert.strip).to eq(<<~ASCIIDOC.chomp)
      . One
      . Two
      . Three
    ASCIIDOC
  end

  example "<ul><li>One<li>Two<li>Three</ul>" do
    expect(subject.convert.strip).to eq(<<~ASCIIDOC.chomp)
      * One
      * Two
      * Three
    ASCIIDOC
  end

  example "complicated example" do
    src = <<~HTML
      This text <b>consists of</b> rich text with <i>some elements being
      implicitly-<sup>ended</i>.
      <p>It also has paragraphs,<br>line breaks &amp; entities,
      including &rarr;Unicode&larr; ones.
      <p>And finally, a <a href="http://example.com">link</a>!
    HTML

    expectation = <<~ASCIIDOC.chomp
      This text *consists of* rich text with _some elements being \
      implicitly-^ended^_.

      It also has paragraphs, +
      line breaks & entities, \
      including \u2192Unicode\u2190 ones.

      And finally, a http://example.com[link]!
    ASCIIDOC

    expect(described_class.new(src).convert).to eq(expectation)
  end

end
