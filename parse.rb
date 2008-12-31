require 'yaml'

module Gem
	class Specification < Hash
	end
	class Requirement < Hash
	end
	class Version
		def to_s
			@version
		end
		def inspect
			to_s
		end
	end
end

deb_keys = ['Package', 'Version', 'Architecture', 'Maintainer', 'Installed-Size', 'Depends', 'Homepage', 'Priority', 'Section', 'Description']

description = ''

meta = YAML::load($stdin.read)
meta.each do |k,v|
	next if k == 'has_rdoc'
	next if k == 'summary'
	next if k == 'email'
	next if k == 'required_ruby_version'
	k = k.capitalize
	if k == 'Name'
		k = 'Package'
		v = "lib#{v}-rubygem"
	end
	if k == 'Description'
		v = "#{meta['summary']}\n #{v.gsub(/\.\s+/, ".\n ")}"
		description = v
		next
	end
	if k == 'Dependencies'
		k = 'Depends'
		v << 'ruby' + (meta['required_ruby_version']['version'] ? "(>= #{meta['required_ruby_version']['version']})" : '')
	end
	if k == 'Authors'
		k = 'Maintainer'
		v = "#{v} <#{meta['email']}>"
	end
	unless deb_keys.include?k
		k = "X-#{k}"
	end
	if v.is_a?Array
		v = v.join(',')
	end
	if v.is_a?Hash
		v = v.inspect
	end
	puts "#{k}: #{v}"
end

puts "Description: #{description}"
