require "spec_helper"

RSpec.describe "string conversion refinements" do
  using Iev::Termbase::DataConversions

  describe "#decode_html" do
    it "decodes HTML entities" do
      str = "&lt;b&gt;what a&lt;/b&gt; string &&amp; stuff"
      expect(str.decode_html).to eq("<b>what a</b> string && stuff")
    end

    it "returns decoded string but leaves self unchanged" do
      str = "&lt;&gt;"
      expect { str.decode_html }.not_to change { str }
      expect(str.decode_html).not_to eq(str)
    end
  end

  describe "#decode_html!" do
    it "decodes string in place" do
      str = "&lt;&gt;"
      expect { str.decode_html! }.to change { str }.to("<>")
    end
  end

  describe "#sanitize" do
    it "strips leading and trailing white spaces" do
      str = "  whatever\t"
      expect(str.sanitize).to eq("whatever")
    end

    it "removes uFEFF sequences" do
      str = "what\uFEFFever"
      expect(str.sanitize).to eq("whatever")
    end

    it "replaces u2011 (non-breaking dashes) with regular dashes" do
      str = "what\u2011ever"
      expect(str.sanitize).to eq("what-ever")
    end

    it "replaces u00a0 with regular spaces" do
      str = "what\u00a0ever"
      expect(str.sanitize).to eq("what ever")
    end

    it "returns sanitized string but leaves self unchanged" do
      str = "  what\uFEFFever\t"
      expect { str.sanitize }.not_to change { str }
      expect(str.sanitize).not_to eq(str)
    end
  end

  describe "#sanitize!" do
    it "sanitizes string in place" do
      str = "  whatever\t"
      expect { str.sanitize! }.to change { str }.to("whatever")
    end
  end
end
