module Zombiehome
	module Readline
		module Completer
			ObjTypeSymbols = %i{
				table
				view
			}

			TableMethodWords = %w{
				select
				insert
				update
				delete
			}

			ViewMethodWords = %w{
				select
				insert
				update
				delete
			}

			@context = nil

			CompletionProc = ->(input) {
				case input
				when /^[a-zA-Z][^.]*$/, ""
					# variable's name

			        # gv = @context.eval("global_variables").collect{|m| m.to_s}
			        # lv = @context.eval("local_variables").collect{|m| m.to_s}
			        # iv = @context.eval("instance_variables").collect{|m| m.to_s}
			        # cv = @context.eval("self.class.constants").collect{|m| m.to_s}

		        	@dbs.grep(/^#{input}/)
			    when /^([^."].*)(\.|::)([^.]*)$/
			    	receiver = $1
			        sep = $2
			        message = Regexp.quote($3)

			        candidates = @context.eval(%Q{
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
		end
	end
end