require 'open-uri'
require 'zlib'
require 'yaml'

begin
	require 'sqlite3'
	module SQLite3
		class Database
			class << self
				alias :quote_string_only :quote
				def quote(val)
					quote_string_only(val.to_s)
				end
			end
		end
	end
rescue LoadError
	warn 'SQLite3 not found, saving to db will not work'
end

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

	def to_s
		"deb #{@baseurl} #{@distro} #{@sections.join(' ')}"
	end

	def inspect
		refresh unless @packages
		'# ' + to_s + "\n" + YAML::dump(@packages)
	end

	def save_to_sqlite(parameters)
		# The caller passes us a sqlite3 db, we can assume it's been included
		refresh unless @packages
		parameters[:packages] = 'packages'
		parameters[:depends] = 'depends'
		@packages.each do |package, data|
			begin
				parameters[:db].execute("INSERT INTO #{parameters[:packages]}" \
				" (package, version, maintainer, installed_size, size, homepage, section, remote_path, md5, description)" \
				" VALUES ('#{SQLite3::Database::quote(package)}', '#{SQLite3::Database::quote(data['Version'])}', '#{SQLite3::Database::quote(data['Maintainer'])}'," \
				" #{data['Installed-Size']}, #{data['Size']}, '#{SQLite3::Database::quote(data['Homepage'])}'," \
				" '#{SQLite3::Database::quote(data['section'])}', '#{SQLite3::Database::quote(@baseurl + data['Filename'])}', '#{SQLite3::Database::quote(data['MD5sum'])}'," \
				" '#{SQLite3::Database::quote(data['Description'])}')")
			rescue SQLite3::SQLException
				parameters[:db].execute("UPDATE #{parameters[:packages]} SET" \
				" version='#{SQLite3::Database::quote(data['Version'])}', maintainer='#{SQLite3::Database::quote(data['Maintainer'])}'," \
				" installed_size=#{data['Installed-Size']}, size=#{data['Size']}," \
				" homepage='#{SQLite3::Database::quote(data['Homepage'])}', section='#{SQLite3::Database::quote(data['section'])}'," \
				" remote_path='#{SQLite3::Database::quote(@baseurl + data['Filename'])}', md5='#{SQLite3::Database::quote(data['MD5sum'])}'," \
				" description='#{SQLite3::Database::quote(data['Description'])}'" \
				" WHERE package='#{SQLite3::Database::quote(package)}'")
			end
		end
	end

	private

	def refresh
		@packages = {}
		base = @baseurl + 'dists/' + @distro + '/'
		@sections.each do |section|
			@arch.each do |arch|
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
