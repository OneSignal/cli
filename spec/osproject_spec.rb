require 'osproject'
require 'osproject_android'
require 'osproject_ios'
require 'tmpdir'

sdkmap = {
  'googleandroid' => OSProject::GoogleAndroid,
  'ios' => OSProject::IOS,
}

Dir.foreach("spec/samples") do |platform|
  next if platform == '..' or platform == '.'
  proj_class = sdkmap[platform]
  Dir.foreach("spec/samples/" + platform) do |lang|
    next if lang == '..' or lang == '.'
    Dir.foreach("spec/samples/" + platform + '/' + lang) do |sampledirname|
      next if sampledirname == '..' or sampledirname == '.'
      sampledir = 'spec/samples/' + platform + '/' + lang + '/' + sampledirname
      tmpdir = Dir.mktmpdir()
      projdir = tmpdir + '/' + sampledirname
      RSpec.describe OSProject, ".add_sdk" do
        before(:all) do
          FileUtils.cp_r(sampledir, projdir, verbose: true)
        end
        after(:all) do
          #FileUtils.remove_entry tmpdir
        end
        context sampledirname do
          it "successfully instantitates the object" do
            proj = proj_class.new(projdir, lang, 'app_id')
            expect(proj.type.to_s).to eq platform
            expect(proj.dir).to eq projdir
          end
          it "successfully adds sdk" do
            proj = proj_class.new(projdir, lang, 'app_id')
            if platform == 'googleandroid'
              # For Android samples, we have a appclassfile symlink in the proj root dir
              # When users use the CLI, they specify the file.
              proj.app_class_location = '.appclassfile'
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
