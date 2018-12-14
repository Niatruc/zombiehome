module Kernel
	def pd(*args)
		if $debug
			args.each do |a|
				p a
			end
		end
	end
end