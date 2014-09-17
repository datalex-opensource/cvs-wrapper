# cvs_spec.rb
require 'rubygems'
require 'fileutils'
require 'logger'
require_relative '../lib/cvs'


def create_cvs_module(cvs, module_name, *files)
  Dir.mkdir(module_name)
  files.each { |item| FileUtils.touch(File.join(module_name, item)) }
  cvs.import(module_name)
  FileUtils.rm_rf module_name
end

def prepare_repo(cvs)
  create_cvs_module(cvs, 'module1', 'Readme.txt', 'File1.java', 'File2.java')
  create_cvs_module(cvs, 'module2', 'Readme.txt', 'File1.java', 'File2.java', 'fil with spaces.txt')
  cvs.rtag('module1', 'branch1', branch: true)
  cvs.rtag('module2', 'branch1', branch: true)
end


describe CVS do

  before(:each) do
    dir = Dir.mktmpdir
    working_dir = Dir.mktmpdir
    logger = Logger.new(STDOUT)
    logger.level = Logger::ERROR
    @cvs = CVS.init(dir, '/usr/bin/cvs', logger) do |cvs|
      Dir.chdir(working_dir) { prepare_repo(cvs) }
    end
    @cvs.config do |settings|
      settings[:basedir] = working_dir
    end
  end

  it 'checks out a cvs file' do    
    result = @cvs.checkout 'module1/File1.java'
    FileUtils.rm_rf File.join(@cvs.root,'module1')
    result.should eq "U module1/File1.java\n"
  end

  it 'checks out a cvs file with whitespaces on the filename' do    
    result = @cvs.checkout 'module2/fil with spaces.txt'
    FileUtils.rm_rf File.join(@cvs.root,'module2')
    result.should eq "U module2/fil with spaces.txt\n"
  end

  it 'checks out a cvs file that does not exist' do
    expect {
      @cvs.checkout 'module1/does_not_exist.txt'
    }.to raise_error CVSOperationError
  end

  it 'changes cvs basedir config' do
    @cvs.config do |settings|
      settings[:basedir] = 'new/basedir'
    end
    @cvs.settings[:basedir].should eq 'new/basedir'
  end

  it 'Checks out, changes and commits a file' do
    result = @cvs.checkout 'module2/File1.java'
    result.should include "module2/File1.java\n"
    #modifying resource
    open(File.join(@cvs.root,'module2/File1.java'), 'a') { |file| file << "Some extra text\n" }
    #committing resource
    result = @cvs.commit 'module2/File1.java', 'Test Commit'
    result.should include('module2/File1.java')
    result.should include('new revision')
  end

  it 'asserts root returns the configured basedir'do
    @cvs.config do |settings|
      settings[:basedir] = 'changed the basedir'
    end
    @cvs.root().should eq 'changed the basedir'
  end

  it 'logs the status of a file' do
    @cvs.checkout 'module1/File1.java'
    result = @cvs.status('module1/File1.java')
    result.should_not eq ''
  end

  it 'gets the current branch and branch revision of a file that is HEAD' do
    @cvs.checkout 'module1/File1.java'
    branch, rev = @cvs.current_branch('module1/File1.java')
    branch.should eq 'HEAD'
    rev.should match /^\d[\.\d+]+/
  end

  it 'gets the current branch and branch revision of a file that is branch1' do
    @cvs.checkout 'module1/File1.java', branch: 'branch1'
    branch, rev = @cvs.current_branch('module1/File1.java')
    branch.should eq 'branch1'
    rev.should match /^\d[\.\d+]+/
  end

  it 'gets the current revision of a file that is HEAD' do
    @cvs.checkout('module1/File1.java', branch: 'HEAD')
    rev = @cvs.current_revision('module1/File1.java')
    rev.should match /^\d[\.\d+]+/
  end

  it 'gets the current revision of a file that is on Branch1' do
    @cvs.checkout 'module1/File1.java', branch: 'branch1'
    rev = @cvs.current_revision('module1/File1.java')
    rev.should match /^\d[\.\d+]+/
  end

  after(:each) do
    FileUtils.rm_rf @cvs.cvsroot
    FileUtils.rm_rf @cvs.root
  end

end

