require 'open3'
require 'childprocess'
cmd = "/usr/bin/cvs -d :ext:fabioneves@localhost/home/fabioneves/repos/cvs co \"module2/file a 2\""

current_dir ='/home/fabioneves/.mirror/cvs/6d5b0f8996c404038c040b0355c10871'




begin
  result = StringIO.open do |io|
    io.sync
    # args = cmd.split
    # puts args
    process = ChildProcess.build('/usr/bin/cvs','-d',':ext:fabioneves@localhost/home/fabioneves/repos/cvs','co', 'module2/fil with spaces.txt' )
    process.cwd = current_dir
    process.environment['CVSROOT'] = nil
    process.io.stdout = process.io.stderr = io
    process.start
    process.poll_for_exit(200)
    io.string
  end
  puts result

rescue => e
  puts e.message
end













# Open3.popen3('/bin/bash',"cd #{current_dir} && #{cmd}" ) do |stdin, out, err, wait_thr|
#   pid = wait_thr.pid # pid of the started process.
#   stdin.close
#   result = out.read
#   out.close
#   # result += err.read
#   err.close
#   exit_status = wait_thr.value # Process::Status object returned.
#   puts "io: #{result}"
#   puts "exit_status #{exit_status} "
# end
# #
#
# result = ''
# IO.popen("/bin/bash cd #{current_dir} && #{cmd}") do |io|
#   io.each do |line|
#     result += line
#     puts "-- #{line}"
#   end
#   io.close
# end

