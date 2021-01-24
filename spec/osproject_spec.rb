require 'osproject'
require 'tmpdir'

sdkmap = {
  "android" => OSProject::GoogleAndroid,
  "ios" => OSProject::IOS,
}

Dir.foreach("spec/samples") do |sdk|
  next if sdk == '..' or sdk == '.'
  sdk_class = sdkmap[sdk]
  Dir.foreach("spec/samples/" + sdk) do |sampledir|
    next if sampledir == '..' or sampledir == '.'
    tmpdir = Dir.mktmpdir()
    projdir = tmpdir + '/' + sampledir
    RSpec.describe OSProject, ".add_sdk" do
      before(:all) do
        puts 'sampledir: ', 'spec/samples/' + sdk + '/' + sampledir
        puts 'projdir: ', projdir
        FileUtils.cp_r('spec/samples/' + sdk + '/' + sampledir, projdir, verbose: true)
      end
      after(:all) do
        FileUtils.remove_entry tmpdir
      end
      context sampledir do
        it "successfully instantitates the object" do
          proj = sdk_class.new(projdir, 'lang', 'app_id')
          expect(proj.type).to eq sdk
          expect(proj.dir).to eq projdir
        end
        it "successfully adds sdk" do
          proj = sdk_class.new(projdir, 'lang', 'app_id')
          expect(proj.has_sdk?()).to eq false
          proj.add_sdk()
          expect(proj.has_sdk?()).to eq true
        end
      end
    end
  end
end
