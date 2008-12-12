#!/usr/bin/ruby

require 'optparse'
require 'sqlite3'
require 'apt'

options = {
	:config => 'testrepo.txt',
	:database => 'test.db'
}

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"
	opts.on('-c', '--config [PATH]', 'Config file') do |v|
		options[:config] = v
	end
	opts.on('-d', '--database [PATH]', 'Database file') do |v|
		options[:database] = v
	end
end.parse!

db = SQLite3::Database.new(options[:database])
db.execute("CREATE TABLE IF NOT EXISTS packages (package TEXT PRIMARY KEY, version TEXT, maintainer TEXT, installed_size INTEGER, size INTEGER, homepage TEXT, section TEXT, remote_path TEXT, md5 TEXT, description TEXT, status INTEGER)")
db.execute("CREATE TABLE IF NOT EXISTS depends (package TEXT, depend TEXT, version TEXT)")

open(options[:config]).read.split(/\n/).each |debline|
	next if debline[0..1] == '#'
	APT.new(debline).save_to_sqlite(:db => db)
end
