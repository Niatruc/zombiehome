module Zombiehome
	# if !$debug
	# 	class Table<BasicObject; end
	# else
	# 	class Table; end
	# end
	class DBFactory
		class Table
			Column = ::Struct.new(*%i{
				column_name
				ordinal_position
				column_comment
				data_type
				numeric_precision
				numeric_scale
				column_default
				column_type
				column_key
				is_nullable
				character_maximum_length
				character_octet_length
				extra
				privileges
				generation_expression
			}) do
				def to_s
					members.reduce("") do |s, m|
						s + "#{m}: #{self[m]}\t"
					end
				end
			end

			class << self
				def create_table_dao(table_info)
					if !(table_info.class <= Hash)
						raise 'Expect an argument of Hash type' 
					end

					table = self.new

					table.instance_eval do
						@table_name = table_info[:table_name]
						@primary_key_name_list = []
						@db = table_info[:db]
						@basic_select_sql = %Q{
							select
								*
							from
								#{@table_name}
						}

						@row_format = :hash

						refresh_columns_info
					end

					table
				end

			end

			attr_accessor :row_format

			# Display the table's structure.
			def to_s
				if !@columns
					refresh_columns_info
				end

				"[TableName]\n" +
				"#{@table_name}\n" +
				"[ColumnsInfo]\n" +
				%Q{#{@columns.reduce("") {|s, c| s + c.to_s + "\n" }}\n}
			end

			def refresh_columns_info
				
			end

			def methods
				%i{
					select
					insert
					update
					delete
				}
			end

			def select(*args)
				rs = []
				rs_format = []

				# The primitive sql string that is to be executed.
				select_sql = @basic_select_sql.clone

				# This variable is used to store all arguments that are to be passed to the sql string.
				prepared_args_for_sql = []

				# If no argument is given, then select all records from the table
				if !args[0]
					rs = @db.select(select_sql, [])
				else
					appendix = ""
					if !(args[0].class <= Integer)
						select_sql += " WHERE "
						appendix = " 1 = 0 "
					end

					while !args.empty?
						arg = args.first
						if arg.class <= Integer
							# The limit numbers are expected to be the last arugments.
							break

						elsif arg.class <= Array
							condition_sql, args_for_sql = analyze_array_type_arg(arg)
							prepared_args_for_sql.concat(args_for_sql)

						elsif arg.class <= Hash
							condition_sql, args_for_sql = analyze_hash_type_arg(arg)
							prepared_args_for_sql.concat(args_for_sql)
						end

						select_sql += " #{condition_sql} OR "

						args.shift
					end

					select_sql += appendix
					rs = @db.select(select_sql, prepared_args_for_sql, *args)
				end

				# Transform the result.
				rs_format = transform_result(rs)
			end

			def transform_result(rs)
				rs_format = []

				case @row_format
				when :hash
					rs.each do |r|
						h = {}
						@columns.each do |c|
							h[c.column_name] = r[c.column_name]
						end
						rs_format << h
					end
				else
					rs_format = rs
				end

				rs_format
			end

			def analyze_array_type_arg(arg)
				condition_sql = ""
				args_for_sql = []

				if arg.class <= Array
					item_class = arg[0].class
					in_val_str = ""
					arg.each do |a|
						if a.class != item_class
							$raise.("All items' types should be consistent.")

						# If the table have a compositive primary key:
						elsif item_class <= Array
							in_val_str += %Q{(#{("?," * a.length).chop}),}
							args_for_sql.concat(a)
							
						else
							in_val_str += "?,"
							args_for_sql << a
						end
					end
					condition_sql = %Q{ (#{@primary_key_name_list.join(',')}) IN (#{in_val_str.chop}) }
				end

				[condition_sql, args_for_sql]
			end

			def analyze_hash_type_arg(arg)
				condition_sql = ""
				args_for_sql = []
				appendix = " 1 = 1 "

				if arg.class <= Hash
					arg.each do |col, val|
						if col.class <= Symbol || col.class <= String
							col = quote_col_name(col)

							# last_name: ['zhao', 'qian', 'sun', 'li']
							if val.class <= Array and val.length > 0
								condition_sql += %Q{ #{col} IN (#{ ("?," * val.length).chop }) AND }
								args_for_sql.concat(val)

							# birthday: '1990-01-01'..'2018-12-31',
							elsif val.class <= Range
								condition_sql += %Q{ #{col} BETWEEN ? AND ? AND }
								args_for_sql << val.begin
								args_for_sql << val.end

							# gender: '0',
							else
								condition_sql += %Q{ #{col} = ? AND }
								args_for_sql << val
							end

						elsif col.class <= Integer
							# 0 => "address is not null",
							if val.class <= String
								condition_sql += " #{val} AND "

							# 0 => ["id >= ?", [10]]
							elsif val.class <= Array
								if val[0].class <= String and val[1].class <= Array
									condition_sql += " #{val[0]} AND "
									args_for_sql.concat(val[1])
								end
							end
						end

					end
				end
				[condition_sql + appendix, args_for_sql]
			end

			# Wrap the column name with quotes if necessary.
			def quote_col_name(col_name)
				col_name.to_s
			end
		end
	end
end
