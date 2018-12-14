require_relative "../../zombiehome_test"
require "zombiehome"

class ZombiehomeTest::Table
	class TableTest < Minitest::Test
		def setup
			db = Object.new
			class << db
				def select(sql_stmt, args, *other_args)
					puts sql_stmt
					p args, other_args
					[]
				end
			end
			@table = Zombiehome::DBFactory::Table.create_table_dao({
				table_name: "users",
				db: db,
			})

			@table.instance_eval do
				columns = []
				%w{
					id
					first_name
					last_name
					gender
					birthday
					address
					description
				}.each do |col|
					column = Zombiehome::DBFactory::Table::Column.new
					column.column_name = col
					columns << column
				end
				@columns = columns
				@primary_key_name_list = ["id"]
			end
		end


	 	def test_select
	 		begin
		 		puts "query all records"
		 		@table.select
		 		puts "query records: limit 1"
		 		puts @table.select(1)
		 		puts "query records: limit 1,2"
		 		puts @table.select(1, 2)
		 		# puts "query records: select by primary key: ('0'), ('1')"
		 		# puts @table.select(['0', '1'])
		 		puts "query records: select by conditions"
		 		puts @table.select({
					gender: '0', 
					last_name: ['zhao', 'qian', 'sun', 'li'],
					birthday: '1990-01-01'..'2018-12-31',
					0 => "address is not null",
					1 => ["id > ?", [2]],
				})

		 		puts "query records: pass different types of arguments to `select`"
		 		puts @table.select({
					gender: '0', 
					1 => ["id > ?", [2]],
				}, 
				['1', '2'], {
					gender: '1', 
					birthday: '1990-01-01'..'2018-12-31',
					0 => "address is not null",
				}, 2, 4)

				@table.instance_eval do
					@primary_key_name_list = ['first_name', 'last_name']
				end
				puts @table.select({
					gender: '0', 
					1 => ["id > ?", [2]],
				}, 
				[['zhang', 'bohan'], ['zhao', 'bohan']], 4)

		 		assert true
	 		rescue Exception => e
	 			p e.message
	 			e.backtrace.each {|b| p b}
	 		end
	 	end
	end

end
