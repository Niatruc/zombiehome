require 'readline'
require_relative 'completer'
require_relative '../../zombiehome.rb'

module Zombiehome::Readline
	extend Readline

	self.completion_append_character = nil
	self.completion_proc = Completer::CompletionProc

	class << self
		def start(tip)
			context = binding
			Completer.instance_variable_set(:@context, context)
			Completer.instance_variable_set(:@dbs, [])

			text = ""

			while true 
				text = readline(tip, true)

				begin
					case text
					when "quit", "q"
						break
					when "connect", "conn", 'c'
						context.eval(%Q{
							db = Zombiehome::DBFactory.create
						})
						Completer.instance_variable_get(:@dbs) << 'db'
					else
						puts context.eval(text)
					end
				rescue Exception => e
					puts e.message
					e.backtrace.each {|b| puts b}
				end
			end
		end
	end
end