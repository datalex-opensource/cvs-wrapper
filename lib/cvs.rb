require 'logger'
require 'childprocess'

class CVSOperationError < StandardError; end

class CVS

  HEAD = 'HEAD'

  def initialize(log=nil)
    @logger = log||Logger.new(STDOUT)
    @settings = {
        :basedir => '.',
        :root  => '',
        :executable => '/usr/bin/cvs',
        :default_branch => 'HEAD',
        :timeout => 300
    }

  end

  # wrapper around cvs common tasks
  def root
    settings[:basedir]
  end

  def settings
    return @settings
  end

  def add(filename)
    check_file filename
    parts = filename.split('/')
    parent = parts.shift
    file = parts.join '/'
    file = '' if file.nil?
    cmd = [cvs, '-d',cvsroot,'add', file]
    return execute_command cmd, File.join(root, parent)
  end

  def remove(filename)
    check_file filename
    parts = filename.split('/')
    parent = parts.shift
    file = parts.join '/'
    file_path = File.join(root, filename)
    File.delete(file_path) if File.exists?(file_path)
    cmd = [cvs,'-d',cvsroot,'remove',file]
    return execute_command cmd, File.join(root, parent)
  end

  def co(file_name, branch = '')
    @logger.debug('The method co is deprecated. Please change to the "checkout" method!')
    check_CVSROOT()
    cmd = [cvs,'-d',cvsroot, 'co']
    cmd += ['-r', branch] unless ['', HEAD].include?(branch)
    cmd.push file_name
    return execute_command cmd
  end

  def checkout(file_name, options={})
    check_CVSROOT()
    cmd = [cvs,'-d',cvsroot, 'co']
    cmd += ['-D', options[:timestamp] ] if options[:timestamp]
    cmd += ['-r',options[:branch] ] if options[:branch] and not ['', HEAD].include?(options[:branch])
    cmd.push file_name
    execute_command(cmd, options[:basedir])
  end

  def commit(file_name, comment)
    check_CVSROOT()
    check_file(file_name) unless file_name.nil?
    cmd = [cvs, '-d', cvsroot, 'commit', '-m', comment]
    cmd.push(file_name) unless file_name.nil?
    execute_command cmd
  end

  def config( &block)
    block.call @settings
  end

  def reset_settings
    @settings = {
        :basedir => '.',
        :root => '',
        :executable => '/usr/bin/cvs',
        :default_branch => 'HEAD',
        :timeout => 300
    }
  end

  def status(file_name)
    check_CVSROOT()
    check_file(file_name)
    cmd = [cvs, '-d', cvsroot, 'status', file_name]
    execute_command cmd
  end

  def current_branch(file_name)
    check_file(file_name)
    status = status(file_name).split("\n")
    result = status.grep(/Tag/) do |line|
      if line.include? 'none' then
        rev = status.grep(/Repository revision/) { |repo_revision| repo_revision.split()[2]}[0]
        return HEAD, rev
      end
      parts = line.split(':')
      branch = parts[1].strip.scan(/(.*)\(branch/)[0][0].strip
      branch_revision = parts[2].strip.scan(/(.*)\)/)[0][0].strip
      return branch, branch_revision
    end
    return result
  end

  def current_revision(file_name)
    check_file(file_name)
    status(file_name).split("\n").grep(/Repository revision/) {|repo_revision| repo_revision.split()[2]}[0]
  end

  def previous_revision(file_name)
    check_file(file_name)
    calculate_previous_revision(current_revision(file_name))
  end

  def calculate_previous_revision(current_rev)
    return '1.1' if current_rev.nil? or current_rev == 'NONE'
    parts = current_rev.split('.')
    last_index = parts.length-1
    parts[last_index] = Integer(parts[last_index]) - 1
    if parts[last_index] == 0 and last_index >= 3 then
      #when it is a branch or a branch of a branch
      parts.delete_at(last_index)
      parts.delete_at(last_index-1)
    end

    #when you try to go to a previous version on head and there is no "go back" possible return 1.1
    return '1.1' if parts[last_index] == 0 and last_index == 2
    return parts.join('.')
  end

  def update(file_name, branch)
    full_name = File.join(root(), file_name)
    if File.exists? full_name then
      File.delete full_name
    end
    co(file_name, branch)
  end

  def last_diff(file_name, base_rev=nil)
    if base_rev.nil? or base_rev == 'NONE' then
      rev = current_revision(file_name)
    else
      rev = base_rev
    end
    previous_rev = calculate_previous_revision(rev)
    return diff(previous_rev, rev, file_name)
  end

  def diff(from_rev, to_rev, file_name)
    check_CVSROOT()
    cmd = [cvs, '-d', cvsroot, 'rdiff', '-u', '-r', from_rev, '-r', to_rev, file_name]
    execute_command cmd
  end

  def apply_patch(file_name, patch_file)
    cmd = ['patch', file_name, patch_file]
    execute_command cmd
  end

  def apply_patch_to_root(patch_file)
    cmd = ['patch', '<', patch_file]
    execute_command cmd
  end

  def get_file_content(file_name, revision, basedir=nil)
    cmd = [cvs, '-d', cvsroot, 'co', '-r', revision, file_name]
    execute_command cmd , basedir
    working_dir = basedir.nil? ? root : basedir
    full_path = File.join(working_dir, file_name)
    File.open(full_path, 'r').read
  end

  def get_file_content_as_binary(file_name, revision, basedir=nil)
    cmd = [cvs, '-d', cvsroot, 'co', '-r', revision, file_name]
    execute_command cmd , basedir
    working_dir = basedir.nil? ? root : basedir
    full_path = File.join(working_dir, file_name)
    File.open(full_path, 'rb').read
  end

  def check_file(file_name)
    target_file = File.join(root(), file_name)
    unless File.exists?(target_file)
      @logger.warn "Could not find #{target_file}. Are you sure you have set the correct CVS basedir?"
    end
  end

  def check_CVSROOT
    raise CVSOperationError, 'No CVSROOT specified!' if  cvsroot.empty?
  end

  def cvsroot
    @settings[:root]
  end

  def default_branch
    return HEAD
  end

  def branch_module(sub_module, branch, basedir=nil)
    cmd = [cvs, '-d', cvsroot, 'rtag', '-b', branch, sub_module]
    execute_command cmd , basedir
  end

  private

  def cvs
    settings[:executable]
  end

  def execute_command(cmd, basedir = nil, timeout=nil)
    basedir = basedir.nil? ? root : basedir
    @logger.debug("Executing command #{cmd.join(' ')} | CWD: #{basedir}")
    command_timeout = timeout||settings[:timeout]
    out = Tempfile.new('cvs_cmd')
    process = ChildProcess.build(*cmd)
    process.cwd = basedir
    process.io.stdout = process.io.stderr = out
    process.start
    process.poll_for_exit(command_timeout)
    out.rewind
    result = out.read
    raise CVSOperationError, "Could not successfully execute command '#{cmd}'\n#{result}" if process.exit_code != 0
    result
  rescue ChildProcess::TimeoutError
    raise CVSOperationError, "TIMEOUT[#{command_timeout}]! Could not successfully execute command '#{cmd}'"
  ensure
    out.close if out
    out.unlink if out
  end

end

