require 'dbi'
module Zombiehome::DbiWrapper
	
	def connect(url, user, password, *args)
		@dbh = DBI.connect(url, user, password, *args)
	end	

	def close
		@dbh.disconnect
	end	

	# args should be Array type
	def select(sql_stmt, args)
		# puts sql_stmt, args
		rs = @dbh.select_all(sql_stmt, *args)
	end	

	def limited_select(sql_stmt)
	end	

	def select_and_handle(sql_stmt, *args)
		rs = select(sql_stmt, args)
		if block_given?
			rs.each do |r|
				yield(r)
			end
		end
	end	

	def do(sql_stmt, args_arr)
		@dbh.do(sql_stmt)
	end

	def exec_stmt(sql, *args)
		begin
			sth = @dbh.prepare(sql)
			sth.execute(args)
			sth.finish
			@dbh.commit
			puts "Record has been created"
			yield() if 1
		rescue DBI::DatabaseError => e
		    puts "An error occurred"
		    puts "Error code:    #{e.err}"
		    puts "Error message: #{e.errstr}"
		    @dbh.rollback
		ensure

		end
	end
end