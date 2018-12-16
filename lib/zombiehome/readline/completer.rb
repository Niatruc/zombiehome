module Zombiehome
	module Readline
		module Completer

			@context = nil
			@context_queue = []

			CompletionProc = ->(input) {
				case input
				when /^[a-zA-Z][^.]*$/, ""
					# variable's name or method's name

			        # gv = @context.eval("global_variables").collect{|m| m.to_s}
			        lv = @context.eval("::Kernel.local_variables").collect{|m| m.to_s}
			        # iv = @context.eval("instance_variables").collect{|m| m.to_s}
			        # cv = @context.eval("self.class.constants").collect{|m| m.to_s}

			        candidates = search_candidates_under_context(@context, "self")
		        	# @dbs.grep(/^#{input}/)
		        	(candidates + @dbs).grep(/^#{input}/)
			    when /^([^."].*)(\.|::)([^.]*)$/
			    	receiver = $1
			        sep = $2
			        message = Regexp.quote($3)

			        candidates = search_candidates_under_context(@context, receiver)

			        select_message(receiver, message, candidates, sep)
				else
					[]
				end
			}

			def self.select_message(receiver, message, candidates, sep = ".")
				candidates.grep(/^#{message}/).collect do |e|
					case e
					when /^[a-zA-Z_]/
						receiver + sep + e
					when /^[0-9]/
					end
				end
			end

			def self.search_candidates_under_context(context, receiver)
				context.eval(%Q{
		        	begin
						if #{receiver}.is_zbh_tables!
							#{receiver}.tables_list!
						end
		        	rescue Exception => e1
		        		begin
				        	#{receiver}.methods
		        		rescue Exception => e2
		        			[]
		        		end
		        	end
		        }).collect{|m| m.to_s}
			end
		end
	end
end