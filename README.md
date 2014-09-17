cvs-wrapper
===========

A simple ruby wrapper around cvs command line tool.
This gem relies heavily on childprocess, and it is compatible with MRI and JRuby runtimes.
Below you will find more information on how to install and use this gem. For more information about 
all options available please check the specs or dive into the source code 


# How to install?

```bash
gem install cvs-wrapper
```

# How to run all the tests

```bash
rake
```

# How to build the gem
```bash
rake build
```

# Examples of usage

## Create repository
```ruby
cvs = CVS.init('/path/to/cvs/root', '/usr/bin/cvs', logger).config do |settings, logger|
    settings[:basedir] = '/path/to/my/working/dir' #where, by default, cvs commands will be ran. 
end
```

## Open an existing repository and checkout a module
```ruby
cvs = CVS.new(logger).config do |settings|
    settings[:basedir] = '/path/to/basedir'    
    settings[:root] = '/path/to/cvsroot'    
    settings[:executable] = '/usr/bin/cvs'    
end

cvs.checkout 'module1'
cvs.checkout 'module1', branch: 'branch1'
cvs.checkout 'module1', branch: 'branch1', basedir: '/path/to/another/dir', timestamp: '04/14/2006 09:00'

```

## Commit a file

```ruby
cvs.commit 'module2/File1.java', 'Commit Message'    
```

## Tag a module or a file

```ruby
cvs.rtag 'module2', 'tagname'
cvs.rtag 'module2/File.txt', 'tagname'        
```

## Branch a module
```ruby
cvs.rtag 'module1', 'tagname', branch: true
```

## Remove File
```ruby
cvs.remove 'module1/filename'
```

## Add a file
```ruby
cvs.add 'module1/filename'
```

## Current branch of a given file/module
```ruby
cvs.current_branch 'module1/filename'
```

## Current revision of a given file
```ruby
cvs.current_revision 'module1/filename'
```

## Current previous revision of a given file
```ruby
cvs.previous_revision 'module1/filename'
```

## Update file to the most recent version of the specified branch
```ruby
cvs.update 'module1/filename'
```

## Diff between last two revisions
```ruby
cvs.last_diff 'module1/filename'
```
## Diff between two revisions
```ruby
cvs.diff '1.2.3', '1.5.2.1', 'module1/filename1'
```
 


