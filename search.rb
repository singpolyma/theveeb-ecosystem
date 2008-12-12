#!/usr/bin/ruby

require 'optparse'
require 'sqlite3'

options = {
	:list => false,
	:database => 'test.db'
}

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"
	opts.on('-l', '--list', 'Just list by package name') do |v|
		options[:list] = v
	end
	opts.on('-d', '--database [PATH]', 'Database file') do |v|
		options[:database] = v
	end
end.parse!

db = SQLite3::Database.new(options[:database])
db.results_as_hash = true

sql = "SELECT * from packages WHERE package LIKE '%#{SQLite3::Database::quote(ARGV[0].to_s)}%'"
sql << " OR description LIKE '%#{SQLite3::Database::quote(ARGV[0].to_s)}%'" unless options[:list]

db.execute(sql) do |row|
	flags = ''
	flags << 'I' if row['status'].to_i == 1
	flags << 'U' if row['status'].to_i == -1
	puts flags.ljust(2) + "#{row['package']}".ljust(35) \
	           + " #{row['version']}".ljust(25) \
	           + " #{row['description'].split(/\n/)[0]}"
end
