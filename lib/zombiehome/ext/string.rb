class String
	alias_method :link, :+
	def +(other)
		link(other.to_s)
	end
end