require "spec_helper"

RSpec.describe Iev::Termbase::SourceParser do

  let(:builder) { described_class.new("") }

  it "parses 'MOD,ITU" do
    phrase = "702-01-02 MOD,ITU-R Rec. 431 MOD"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "702-01-02 MOD", "ITU-R Rec. 431 MOD" ]).to include(r)
    end
  end

  it "parses 'MOD. ITU" do
    phrase = "161-06-01 MOD. ITU RR 139 MOD"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "161-06-01 MOD", "ITU RR 139 MOD" ]).to include(r)
    end
  end

  it "parses 'XXX-XX-XX, ITU" do
    phrase = "725-12-50, ITU RR 11"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "725-12-50", "ITU RR 11" ]).to include(r)
    end
  end

  it "parses 'XXX-XX-XX, YYY-YY-YY" do
    phrase = "705-02-01, 702-02-07"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "705-02-01", "702-02-07" ]).to include(r)
    end
  end

  it "parses '702-09-44 MOD, 723-07-47, voir 723-10-91" do
    phrase = "702-09-44 MOD, 723-07-47, voir 723-10-91"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "702-09-44 MOD", "723-07-47", "voir 723-10-91" ]).to include(r)
    end
  end

  it "parses 'IEC 62303:2008, 3.1, modified and IEC 62302:2007, 3.2; IAEA 4" do
    phrase = "IEC 62303:2008, 3.1, modified and IEC 62302:2007, 3.2; IAEA 4"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "IEC 62303:2008, 3.1, modified", "IEC 62302:2007, 3.2", "IAEA 4" ]).to include(r)
    end
  end

  it "parses 'CEI 62303:2008, 3.1, modifiée et CEI 62302:2007, 3.2; AIEA 4" do
    phrase = "CEI 62303:2008, 3.1, modifiée et CEI 62302:2007, 3.2; AIEA 4"
    results = builder.split_source_field(phrase)

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "CEI 62303:2008, 3.1, modifiée", "CEI 62302:2007, 3.2", "AIEA 4" ]).to include(r)
    end
  end

end
