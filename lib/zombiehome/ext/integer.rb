class Fixnum
	alias_method :plus, :+
	def +(other)
		if !other
			self
		else
			plus(other)
		end
	end
end

class Bignum
	alias_method :plus, :+
	def +(other)
		if !other
			self
		else
			plus(other)
		end
	end
end