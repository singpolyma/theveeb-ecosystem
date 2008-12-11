# A version number is a kind of number
class VersionNumber < Numeric

	attr_reader :parts, :labels, :literal

	# Create a new VersionNumber 
	def initialize(literal=nil)
		@parts = [0,0,0] # Numeric parts
		@labels = ['major', 'minor', 'patch'] # Alpha parts
		@literal = literal.to_s # The original literal
		case literal
			when String
				part = 0
				previous_part_was_label = false
				# Tokenize the string and calculate the parts
				literal.scan(/(?:\d+)|(?:[A-z]+)|(?:[^\w\d]+)/).each do |token|
					case token
						when /\d/ # Numeric part
							@parts[part] = token.to_i # We can do this because Ruby knows to expand the array to [token], otherwise we'd have to use push
							part += 1
							previous_part_was_label = false
						when /\w/ # Alpha part : this works because numerics are matched by the first rule
							if previous_part_was_label # If there were two alpha components in a row
								@parts[part] = 0 # Default to zero
								part += 1
							end
							@labels[part] = token
							previous_part_was_label = true
					end
				end
			when Array
				@parts = literal.select { |i| i.to_s =~ /^\d+$/ }
			when Hash
				@parts = literal[:parts] if literal[:parts]
				@labels = literal[:labels] if literal[:labels]
				if literal[:literal]
					@literal = literal[:literal]
				else
					@literal = to_s
				end
			when VersionNumber
				@parts = literal.parts
				@labels = literal.labels
				@literal = literal.literal
			when Numeric
				@parts = @literal.split(//).select { |i| i =~ /\d/ }.collect { |i| i.to_i }
			else
				raise ArgumentError.new("Bad type for VersionNumber.new : #{literal.class}")
		end
	end

	# Type conversions

	def to_s
		rtrn = ''
		@parts.each_with_index do |part, i|
			unless !@labels[i] or (i == 0 and @labels[0] == 'major') or (i == 1 and @labels[1] == 'minor' or i == 2 and @labels[2] == 'patch')
				rtrn << '-' + @labels[i]
			else
				rtrn << '.' unless i == 0
			end
			rtrn << part.to_s
		end
		rtrn
	end

	def to_f
		rtrn = 0.0
		@parts.each_with_index do |part, i|
			rtrn += part/(10.0**i)
		end
		rtrn
	end

	def to_i
		@parts[0]
	end

	def dup
		VersionNumber.new(self)
	end

	# Math
	
	def /(v)
		VersionNumber.new(to_f/v)
	end

	def %(v)
		VersionNumber.new(to_f % v)
	end

	def +(v)
		v = VersionNumber.new(v)
		parts = [0,0,0]
		@parts.each_with_index do |part, i|
			parts[i] = part + v.parts[i].to_i
		end
		VersionNumber.new({ :parts => parts, :labels => @labels })
	end

	def -(v)
		v = VersionNumber.new(v)
		parts = [0,0,0]
		@parts.each_with_index do |part, i|
			parts[i] = part - v.parts[i].to_i
			if parts[i] < 0
				parts[i-1] += parts[i]
				parts[i] = 0
			end
		end
		VersionNumber.new({ :parts => parts, :labels => @labels })
	end

	# Comparison

	def <=>(v)
		v = VersionNumber.new(v)
		return 0 if parts == v.parts
		rtrn = 0
		@parts.each_with_index do |part, i|
			if rtrn > 0
				rtrn += part - v.parts[i].to_i if part - v.parts[i].to_i > 0
			elsif rtrn < 0
				rtrn += part - v.parts[i].to_i if part - v.parts[i].to_i < 0
			else
				rtrn += part - v.parts[i].to_i
			end
		end
		rtrn
	end

	def ===(v)
		v = VersionNumber.new(v)
		parts == v.parts
		labels == v.labels
		literal == v.literal
	end

	def nonzero?
		sum = 0
		@parts.each do |part|
			sum += part
		end
		sum != 0
	end

	def zero?
		not nonzero?
	end

	# Positive, non-imaginary number
	def arg; 0; end
	alias angle arg
	def conjugate; self; end
	alias conj conjugate
	alias real conjugate
	def image; 0; end
	alias imag image

end
