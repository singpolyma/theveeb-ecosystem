#!/usr/bin/ruby

# TODO: add ability to redownload deb file and remove specific files... ala undeb but in reverse

`sudo dpkg -r "#{ARGV[0]}"`
