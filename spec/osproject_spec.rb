require 'osproject'
require 'tmpdir'

sdkmap = {
  'googleandroid' => OSProject::GoogleAndroid,
  'ios' => OSProject::IOS,
}

Dir.foreach("spec/samples") do |sdk|
  next if sdk == '..' or sdk == '.'
  sdk_class = sdkmap[sdk]
  Dir.foreach("spec/samples/" + sdk) do |lang|
    next if lang == '..' or lang == '.'
    Dir.foreach("spec/samples/" + sdk + '/' + lang) do |sampledirname|
      next if sampledirname == '..' or sampledirname == '.'
      sampledir = 'spec/samples/' + sdk + '/' + lang + '/' + sampledir
      tmpdir = Dir.mktmpdir()
      projdir = tmpdir + '/' + sampledir
      RSpec.describe OSProject, ".add_sdk" do
        before(:all) do
          puts 'sampledir: ', sampledir
          puts 'projdir: ', projdir
          FileUtils.cp_r(sampledir, projdir, verbose: true)
        end
        after(:all) do
          #FileUtils.remove_entry tmpdir
        end
        context sampledirname do
          it "successfully instantitates the object" do
            proj = sdk_class.new(projdir, lang, 'app_id')
            expect(proj.type.to_s).to eq sdk
            expect(proj.dir).to eq projdir
          end
          it "successfully adds sdk" do
            proj = sdk_class.new(projdir, lang, 'app_id')
            if sdk == :googleandroid
              # For Android samples, we have a appclassfile symlink in the proj root dir
              # When users use the code, they specify the file.
              proj.app_class_location(appclassfile)
            end
            expect(proj.has_sdk?()).to eq false
            proj.add_sdk!()
            expect(proj.has_sdk?()).to eq true
          end
        end
      end
    end
  end
end
