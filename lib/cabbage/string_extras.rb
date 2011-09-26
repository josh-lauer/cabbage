# a couple of extra methods for strings, to make things easier

class String

	# if a blank? method isn't yet defined for strings, do so
	# here. If run within rails, this should already be
	# defined. (via ActiveSupport)
	if !(String.public_method_defined? :blank?)
		def blank?
			self !~ /\S/
		end
	end

	def down_under
		self.gsub("-", "_").downcase	
	end

end # end String class additions