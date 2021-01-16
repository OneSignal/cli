require 'osproject'
require 'tmpdir'

Dir.foreach("spec/samples") do |sampledir|
  next if sampledir == '..' or sampledir == '.'
  Dir.mktmpdir do |tmpdir| 
    projdir = tmpdir + '/' + sampledir

    RSpec.describe OSProject, "#initialize" do
      context sampledir do
        it "successfully instantitates the object" do
          proj = OSProject.new('ios', projdir)
          expect(proj.type).to eq 'ios'
          expect(proj.dir).to eq projdir
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
  end
end

