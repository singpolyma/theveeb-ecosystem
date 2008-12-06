#!/usr/bin/ruby

require 'open-uri'
require 'zlib'
require 'yaml'

#debline = 'deb http://ca.archive.ubuntu.com/ubuntu/ hardy main restricted'
debline = 'deb http://csclub.uwaterloo.ca/~s3weber/apt/ ubuntu game libs'

class APT

	def initialize(debline, arch=['all',RUBY_PLATFORM.split(/-/)[0].sub(/^i\d86$/,'i386')])
		debline = debline.split(/\s+/)
		debline.shift
		@baseurl = debline.shift
		@distro = debline.shift
		@sections = debline.dup
		@arch = arch
		@packages = nil
	end

	def search(pattern=nil)
		refresh unless @packages
		@packages.keys
	end

	def to_s
		"deb #{@baseurl} #{@distro} #{@sections.join(' ')}"
	end

	def inspect
		refresh unless @packages
		'# ' + to_s + "\n" + YAML::dump(@packages)
	end

	private

	def refresh
		@packages = {}
		base = @baseurl + 'dists/' + @distro + '/'
		@sections.each do |section|
			@arch.each do |arch|
puts base + section + '/binary-' + arch + '/Packages.gz'
				gz = Zlib::GzipReader.new(open(base + section + '/binary-' + arch + '/Packages.gz'))
				meta = gz.read
				gz.close
				YAML::load_documents(meta.gsub(/\n\n/,"\n---\n").gsub(/^(\S+: )(.+)/,"\\1|-\n \\2")) do |package|
					next unless package.is_a?Hash
					package['Size'] = package['Size'].to_i if package['Size']
					package['Installed-Size'] = package['Installed-Size'].to_i if package['Installed-Size']
					if package['Depends']
						package['Depends'] = package['Depends'].split(/, /).collect do |dependency|
							dependency = dependency.scan(/^(\S+)\s\((\S+)\s(\S+)\)$/)[0] || [dependency]
							d = {'Package' => dependency[0]}
							d.merge!({'Version' => dependency[2]}) if dependency[2]
							d
						end
					end
					if package['Replaces']
						package['Replaces'] = package['Replaces'].split(/, /).collect do |dependency|
							dependency = dependency.scan(/^(\S+)\s\((\S+)\s(\S+)\)$/)[0] || [dependency]
							d = {'Package' => dependency[0]}
							d.merge!({'Version' => dependency[2]}) if dependency[2]
							d
						end
					end
					@packages[package['Package']] = package
				end
			end
		end
	end

end

puts APT.new(debline).inspect
