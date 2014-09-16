# cvs_spec.rb
require 'rubygems'
require 'fileutils'
require_relative '../lib/cvs'

CVSROOT = ':pserver:fabioneves@localhost/home/fabioneves/repos/cvs'
BASEDIR = '/home/fabioneves/.mirror/cvs'

def config_cvs
  cvs = CVS.new
  cvs.config do |settings|
    settings[:basedir] = BASEDIR
    settings[:root] = CVSROOT
    settings[:executable]
  end
  cvs
end

describe CVS do

  before(:each) do
    @cvs = config_cvs
  end

  it 'checks out a cvs file' do
    config_cvs
    result = @cvs.checkout 'module1/File1.java'
    FileUtils.rm_rf File.join(@cvs.root,'module1')
    result.should eq "U module1/File1.java\n"
  end

  it 'checks out a cvs file with whitespaces on the filename' do
    config_cvs
    result = @cvs.checkout 'module2/fil with spaces.txt'
    FileUtils.rm_rf File.join(@cvs.root,'module2')
    result.should eq "U module2/fil with spaces.txt\n"
  end

  it 'checks out a cvs file that does not exist' do
    expect {
      @cvs.co 'module1/does_not_exist.txt'
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
    rev.should match /^\d\.\d+$/
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

  it 'gets last diff on build.number on branch1' do
    @cvs.checkout 'module1/File1.java', branch: 'branch1'
    @cvs.last_diff('module1/File2.java').should_not eq ''
    #TODO there should be a more powerful test here!!
  end

  after(:each) do
    FileUtils.rm_rf File.join(@cvs.root,'module1')
    FileUtils.rm_rf File.join(@cvs.root,'module2')
  end

  after(:all) do
    FileUtils.rm_rf File.join(@cvs.root,'module1')
    FileUtils.rm_rf File.join(@cvs.root,'module2')
  end

end

