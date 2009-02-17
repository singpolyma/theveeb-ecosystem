#!/usr/bin/ruby

require 'optparse'
require 'open-uri'
require 'tempfile'
require 'sqlite3'
require 'version_number'

$external = {}
if `which apt-cache` != ''
	$external[:get_version] = "apt-cache show '%s' | grep Version | head -n1 | cut -d' ' -f2"
end
if `which apt-get` != ''
	$external[:install] = "sudo apt-get install -y '%s'"
end

$internal_install = "PREFIX='#{ENV['TVEROOT']}/' LOG='#{ENV['TVEROOT']}/var/cache/tve-remove/%p' undeb '%s'"
if `which dpkg` != ''
	$internal_install = "sudo dpkg -i '%s'"
end

options = {
	:config => nil,
	:database => nil,
	:interactive => false
}

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options] [PACKAGE]"
	opts.on('-i', '--interactive', 'Prompt before install') do |v|
		options[:interactive] = v
	end
	opts.on('-c', '--config [PATH]', 'Config file') do |v|
		options[:config] = v
	end
	opts.on('-d', '--database [PATH]', 'Database file') do |v|
		options[:database] = v
	end
	unless ARGV[0]
		warn opts
		exit
	end
end.parse!

unless options[:config]
	if ENV['TVELIST']
		options[:config] = ENV['TVELIST']
	elsif File.exist?(File.expand_path('~/.tve.list'))
		options[:config] = File.expand_path('~/.tve.list')
	elsif File.exist?("#{ENV['TVEROOT']}/etc/tve.list")
		options[:config] = "#{ENV['TVEROOT']}/etc/tve.list"
	elsif File.exist?('/Program Files/TheVeeb/etc/tve.list')
		options[:config] = '/Program Files/TheVeeb/etc/tve.list'
	else
		warn 'No tve.list file found.'
		exit 1
	end
end

unless options[:database]
	if ENV['TVEDB']
		options[:database] = ENV['TVEDB']
	elsif File.exist?(File.expand_path('~/.tve.db'))
		options[:database] = File.expand_path('~/.tve.list')
	elsif File.exist?("#{ENV['TVEROOT']}/var/cache/tve.db")
		options[:database] = "#{ENV['TVEROOT']}/var/cache/tve.db"
	elsif File.exist?('/Program Files/TheVeeb/var/cache/tve.db')
		options[:database] = '/Program Files/TheVeeb/var/cache/tve.db'
	elsif File.exist?('/Library/Caches/tve.db')
		options[:database] = '/Library/Caches/tve.db'
	else
		warn 'No tve.db file found.'
		exit 1
	end
end

$db = SQLite3::Database.new(options[:database])
$db.results_as_hash = true

$done = {}

def install(pkg, interactive=false)
	package = $db.execute("SELECT * FROM packages WHERE package='#{SQLite3::Database::quote(pkg)}' LIMIT 1")[0]

	unless package
		warn "Package: #{pkg} not found."
		return -1
	end

	if package['status'].to_i == 1
		warn "Package: #{pkg} already newest version."
		return 1
	end

	# Resolve dependencies

	$db.execute("SELECT depend,version FROM depends WHERE package='#{SQLite3::Database::quote(pkg)}'") do |row|
		next if $done[row['depend']] && $done[row['depend']] >= VersionNumber.new(row['version'])
		available = $db.execute("SELECT package,version FROM packages WHERE package='#{SQLite3::Database::quote(row['depend'])}' LIMIT 1")[0] rescue nil
		unless available
			available = $db.execute("SELECT is_really FROM virtual_packages WHERE package='#{SQLite3::Database::quote(row['depend'])}' LIMIT 1")[0]['is_really'] rescue nil
			if available
				available = $db.execute("SELECT package,version FROM packages WHERE package='#{SQLite3::Database::quote(available)}' LIMIT 1")[0] rescue nil
			end
		end
		if available && VersionNumber.new(available['version']) >= VersionNumber.new(row['version'])
			if status = install(row['package'], interactive) < 0
				return status
			end
		else
			if $external[:get_version]
				available = `#{$external[:get_version].sub(/%s/,row['depend'])}`.chomp
				if available.to_s != '' && VersionNumber.new(available) >= VersionNumber.new(row['version'])
					doit = !interactive
					if interactive
						print "Install #{row['depend']} using external package manager? [Yn] "
						doit = true if $stdin.gets.chomp != 'n'
					end
					if doit
						if $external[:install]
							unless system($external[:install].sub(/%s/,row['depend']))
								warn "Error installing #{row['depend']} using #{$external[:install]}"
								return -3
							end
						else
							warn 'No external package install command.'
							return -3
						end
						$done[row['depend']] = VersionNumber.new(available)
					else
						return -2
					end
				else
					warn "Package: #{row['depend']} not found. (Or version found too old.)"
					return -1
				end
			else
				warn "Package: #{row['depend']} not found. (Or version found too old.)"
				return -1
			end
		end
	end

	doit = !interactive
	if interactive
		print "Install #{pkg} using external package manager? [Yn] "
		doit = true if $stdin.gets.chomp != 'n'
	end
	if doit
		# TODO: add oauth stuff
		fh = Tempfile.new($0)
		fh.write open(package['remote_path']).read
		fh.close
		unless system($internal_install.sub(/%s/,fh.path).sub(/%p/,pkg))
			warn "Error installing #{pkg} (#{fh.path}) using #{$internal_install}"
			return -3
		end
		$done[pkg] = VersionNumber.new(package['version'])
	else
		return -2
	end

	0
end

exit install(ARGV[0], options[:interactive])
