require 'readline'
require_relative 'completer'
require_relative '../../zombiehome.rb'

module Zombiehome::Readline
	extend Readline

	self.completion_append_character = nil
	self.completion_proc = Completer::CompletionProc

	class << self
		@help_info = %Q{
			quit(q): Exit from this program
			help(h): Print these message
			connect(conn, c): Connect to a database(using configure items specified by user)
			cd <exp>: Turn into another context. For example, `cd db.tables.my_table`, then you could manage the table db.tables.my_table.
				If no exp is given, then it will return to the top level context (which is the same as that context you are first in after lauching this program).
		}

		@commands = %w{
			quit
			help
			connect
		}

		def start(tip)
			appended_tip = ""
			top_context = binding
			context = top_context
			Completer.instance_variable_set(:@context, context)
			context_queue = Completer.instance_variable_set(:@context_queue, [])
			context_queue << context
			Completer.instance_variable_set(:@dbs, [])
			Completer.instance_variable_set(:@commands, @commands)

			text = ""

			while true 
				text = readline("#{tip} #{appended_tip}> ", true)

				begin
					case text
					when "quit", "q"
						break
					when "help", "h"
						puts (self.singleton_class.class_eval { @help_info })
					when "connect", "conn", 'c'
						context.eval(%Q{
							db = Zombiehome::DBFactory.create
						})
						Completer.instance_variable_get(:@dbs) << 'db'
					when /^cd[\s]+(.+)/
						path = $1
						r = context.eval(path)
						begin
							r_class = r.class
							if r_class <= Zombiehome::DBFactory || r_class <= Zombiehome::DBFactory::Table
								context = context.eval(%Q{
									#{path}.instance_eval{ binding }
								})
							end
						rescue Exception => e
							if r.is_zbh_tables!
								# context = r.binding!
								context = context.eval(%Q{
									#{path}.instance_eval!{ ::Kernel.binding }
								})
							end
						end
						Completer.instance_variable_set(:@context, context)
						if /^[\s]*(?<pre_path>[.a-zA-Z0-9_]+)/ =~ appended_tip
							appended_tip = " #{pre_path}.#{path}"
						else
							appended_tip = " #{path}"
						end
						
					when /^cd[\s]*$/
						context = top_context
						Completer.instance_variable_set(:@context, context)
						appended_tip = ""
					else
						r = context.eval(text)
						puts r
					end
				rescue Exception => e
					puts e.message
					e.backtrace.each {|b| puts b}
				end
			end
		end

		def methods
			(self.singleton_class.class_eval { @commands }) + Completer.instance_variable_get(:@dbs)
		end
	end
end