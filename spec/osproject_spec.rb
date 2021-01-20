require 'osproject'
require 'tmpdir'

sdkmap = {
  "android" => OSProject::Android,
  "ios" => OSProject::IOS,
}

Dir.foreach("spec/samples") do |sdk|
  next if sdk == '..' or sdk == '.'
  sdk_class = sdkmap[sdk]
  Dir.foreach("spec/samples/" + sdk) do |sampledir|
    next if sampledir == '..' or sampledir == '.'
    Dir.mktmpdir do |tmpdir| 
      projdir = tmpdir + '/' + sampledir
  
      RSpec.describe OSProject, "#initialize" do
        context sampledir do
          it "successfully instantitates the object" do
            proj = sdk_class.new(projdir, 'lang', 'app_id')
            expect(proj.type).to eq sdk
            expect(proj.dir).to eq projdir
          end
        end
      end
      RSpec.describe OSProject, ".add_sdk" do 
        context "cocoapods + foobar" do
          it "successfully adds sdk" do
            proj = sdk_class.new(projdir, 'lang', 'app_id')
            proj.add_sdk()
            # XXX need to add a check here
          end
        end
      end
    end
  end
end

