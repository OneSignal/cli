require 'osproject'

RSpec.describe OSProject, "#initialize" do
  context "with placeholder values" do
    it "successfully instantitats the object" do
      ios_proj = OSProject.new('ios', 'dir')
      expect(ios_proj.type).to eq 'ios'
      expect(ios_proj.dir).to eq 'dir'
    end
  end
end

RSpec.describe OSProject, ".add_sdk" do 
  context "cocoapods + foobar" do
    it "successfully adds sdk" do
      ios_proj = OSProject.new('ios', 'dir')
      ios_proj.add_sdk()
      # XXX need to add a check here
    end
  end
end
