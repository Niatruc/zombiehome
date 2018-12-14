require_relative "../../zombiehome_test"
require "zombiehome/dbFactory/mysqlDBFactory"

class ZombiehomeTest::DBFactory
	class DBFactoryTest < Minitest::Test
		def setup
	 		@db = Zombiehome::MysqlDBFactory.create

		end

		def teardown
	 		@db.close
		end

	 	def test_connect
	 		assert true
	 	end

	 	def test_refresh_tables_views_list
	 		@db.refresh_tables_views_list
	 		p @db.tables_views_list
	 		assert true
	 	end

	 	def test_tables
	 		begin
		 		@db.tables.ttt
	 		rescue Exception => e
	 			p e.message
		 		assert true
	 		end

	 		begin
		 		@db.tables.t1
	 		rescue Exception => e
	 			e.backtrace.each {|b| p b}
	 		end
	 	end

	 	def test_select
	 		# Zombiehome::DbiWrapper.module_eval do
	 		# 	def select(sql_stmt, *args)
	 		# 		puts sql_stmt, args
	 		# 		[]
	 		# 	end
	 		# end

	 		puts @db.tables.t1
	 		begin
		 		puts "query all records"
		 		puts @db.tables.users.select
		 		puts "query records: with limit, group and order"
		 		puts @db.tables.users.select({
		 			0=> "address is not null"
		 		}, 2, 10, 
		 			o: ["id"],
		 			g: ["last_name", "gender"]
		 		)
		 		assert true
	 		rescue Exception => e
	 			p e.message
	 			e.backtrace.each {|b| p b}
	 		end
	 	end
	end

end
