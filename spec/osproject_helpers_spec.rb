require 'osproject_helpers'

RSpec.describe "_sub_file" do
  it "successfully subsitutes first match with string" do
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
    _sub_file('spec/samplefile.txt', 'foo', 'fbb')
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 3
    expect(contents.scan(/fbb/).length).to eq 1
    _sub_file('spec/samplefile.txt', 'fbb', 'foo')
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
  end
  it "successfully subsitutes first match with block" do
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
    _sub_file('spec/samplefile.txt', 'foo') do |line|
      "fbb"
    end
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 3
    expect(contents.scan(/fbb/).length).to eq 1
    _sub_file('spec/samplefile.txt', 'fbb') do |line|
      "foo"
    end
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
  end
end

RSpec.describe "_gsub_file" do
  it "successfully subsitutes matches with string" do
    contents = File.read('spec/samplefile.txt')
    puts(contents.count('foo'))
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
    _gsub_file('spec/samplefile.txt', 'foo', 'fbb')
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 0
    expect(contents.scan(/fbb/).length).to eq 4
    _gsub_file('spec/samplefile.txt', 'fbb', 'foo')
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
  end
  it "successfully subsitutes matches with block" do
    contents = File.read('spec/samplefile.txt')
    puts(contents.count('foo'))
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
    _gsub_file('spec/samplefile.txt', 'foo') do |line|
      "fbb"
    end
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 0
    expect(contents.scan(/fbb/).length).to eq 4
    _gsub_file('spec/samplefile.txt', 'fbb') do |line|
      "foo"
    end
    contents = File.read('spec/samplefile.txt')
    expect(contents.scan(/foo/).length).to eq 4
    expect(contents.scan(/fbb/).length).to eq 0
  end
end

RSpec.describe "_insert_lines" do
  it "successfully inserts line after marker" do
  end
  it "successfully inserts lines after marker" do
  end
end
