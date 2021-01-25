require "spec_helper"

RSpec.describe Iev::Termbase::SourceParser do
  subject do
    example = RSpec.current_example
    attributes_str = example.metadata[:string] || example.description
    described_class.new(attributes_str)
  end

  example "MOD,ITU", string: "702-01-02 MOD,ITU-R Rec. 431 MOD" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "702-01-02 MOD", "ITU-R Rec. 431 MOD" ]).to include(r)
    end
  end

  example "MOD. ITU", string: "161-06-01 MOD. ITU RR 139 MOD" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "161-06-01 MOD", "ITU RR 139 MOD" ]).to include(r)
    end
  end

  example "XXX-XX-XX, ITU", string: "725-12-50, ITU RR 11" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "725-12-50", "ITU RR 11" ]).to include(r)
    end
  end

  example "XXX-XX-XX, YYY-YY-YY", string: "705-02-01, 702-02-07" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(2)

    results.each do |r|
      expect([ "705-02-01", "702-02-07" ]).to include(r)
    end
  end

  example "702-09-44 MOD, 723-07-47, voir 723-10-91" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "702-09-44 MOD", "723-07-47", "voir 723-10-91" ]).to include(r)
    end
  end

  example "IEC 62303:2008, 3.1, modified and IEC 62302:2007, 3.2; IAEA 4" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "IEC 62303:2008, 3.1, modified", "IEC 62302:2007, 3.2", "IAEA 4" ]).to include(r)
    end
  end

  example "CEI 62303:2008, 3.1, modifiée et CEI 62302:2007, 3.2; AIEA 4" do
    results = subject.src_split

    expect(results.class).to be(Array)
    expect(results.size).to eq(3)

    results.each do |r|
      expect([ "CEI 62303:2008, 3.1, modifiée", "CEI 62302:2007, 3.2", "AIEA 4" ]).to include(r)
    end
  end
end
