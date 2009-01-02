#!/usr/bin/ruby

# Usage convention:
# ruby getrepo.rb -ctestrepo.txt | update/update -dtest.db

require 'optparse'
require 'open-uri'
require 'zlib'
require 'digest/md5'
require 'tempfile'
require 'yaml'

# Deal with command line options
options = {
	:config => 'testrepo.txt',
}

OptionParser.new do |opts|
	opts.banner = "Usage: #{$0} [options]"
	opts.on('-c', '--config [PATH]', 'Config file') do |v|
		options[:config] = v
	end
end.parse!

# Detect this system's architecture
arch = ['all', RUBY_PLATFORM.split(/-/)[0].sub(/^i\d86$/,'i386')]

warn "arch: #{arch.join(', ')}"

# Parse config file, verify repositories, and output metadata
open(options[:config]).read.split(/\n/).each do |debline|
	# parse one line of the config file
	debline.strip!
	next if debline[0..0] == '#' # Ignore comments
	next if debline == '' # Ignore blank lines
	debline = debline.split(/\s+/)
	debline.shift
	baseurl = debline.shift
	distro = debline.shift
	sections = debline.dup

	puts "\n##{baseurl}"

	# Read the release file
	release = open(baseurl + 'dists/' + distro + '/Release').read

	# Read the signature file and verify with gpg
	begin
		fh = Tempfile.new($0).binmode
		fh.write open(baseurl + 'dists/' + distro + '/Release.gpg').read
		fh.close
		sig_path = fh.path

		fh = Tempfile.new($0).binmode
		fh.write release
		fh.close
		release_path = fh.path

		if `sh -c "which gpg"` != ''
			warn `gpg --verify "#{sig_path}" "#{release_path}"`
			unless $?.success?
				raise "FATAL ERROR: GPG verification failed for #{baseurl + 'dists/' + distro + '/Release'}"
			end
		else
			raise 'GPG not found... unable to validate repositories.'
		end

	rescue Exception
		warn $!.inspect
		warn "Release file #{baseurl + 'dists/' + distro + '/Release'} could not be verified"
		exit -1
	end

	sums = {}
	# Parse the release file
	YAML::load(release.gsub(/^ /, ' - '))['MD5Sum'].each do |line|
		line = line.split(/\s+/)
		sums[line[2]] = {:size => line[1].to_i, :md5 => line[0]}
	end

	# Loop over each section and arch
	sections.each do |section|
		arch.each do |a|
			# Get Packages file
			packagelist = baseurl + 'dists/' + distro + '/' + section + '/binary-' + a + '/Packages.gz'
			warn packagelist

			# Try to read package list
			begin
				meta = open(packagelist).read
			rescue OpenURI::HTTPError => e
				# 404 means this section or arch does not exist
				if e.message == '404 Not Found'
					warn "[#{distro}] No arch #{a} in section #{section}"
					next
				else
					raise e
				end
			end

			# Check size and MD5 from Release file
			unless meta.length == sums[section + '/binary-' + a + '/Packages.gz'][:size]
				warn 'Bad size detected for ' + base + section + '/binary-' + a + '/Packages.gz'
				exit -1
			end
			unless Digest::MD5.hexdigest(meta) == sums[section + '/binary-' + a + '/Packages.gz'][:md5]
				warn 'Bad MD5 sum detected for ' + base + section + '/binary-' + a + '/Packages.gz'
				exit -1
			end

			# Actually read and output the Packages data
			def meta.read(dummy); self; end # Pretend to be an IOstream for GzipReader
			gz = Zlib::GzipReader.new(meta)
			meta = gz.read
			puts meta
		end
	end

end
