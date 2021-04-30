require 'osproject'
require 'osproject_ios'
require 'tmpdir'

Dir.foreach("spec/samples/iOS") do |lang|
  next if lang == '..' or lang == '.' or lang.include? "."
  Dir.foreach("spec/samples/iOS/" + lang) do |sampledirname|
    proj_class = OSProject::IOS
    next if sampledirname == '..' or sampledirname == '.' or sampledirname.include? "."
    sampledir = 'spec/samples/iOS/' + lang + '/' + sampledirname
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
          expect(proj.type.to_s).to eq 'ios'
          expect(proj.dir).to eq projdir
        end
        it "successfully adds sdk" do
          proj = proj_class.new(projdir, lang, 'app_id')
          expect(proj.has_sdk?()).to eq false
          proj.add_sdk!()
          expect(proj.has_sdk?()).to eq true
        end
      end
    end
  end
end