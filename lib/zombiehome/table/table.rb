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
						@basic_delete_sql = %Q{
							delete from #{@table_name}
						}

						@row_format = :hash

						refresh_columns_info
					end

					table
				end

			end

			attr_accessor :row_format, :inst_struct

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

			def new_record
				r = inst_struct.new
				r.define_singleton_method(:methods) do
					members
				end
				r
			end

			def methods
				%i{
					select
					insert
					update
					delete
					new_record
				}
			end

			def select(*args)
				rs = []
				rs_format = []

				# The primitive sql string that is to be executed.
				select_sql = @basic_select_sql.clone

				# If no argument is given, then select all records from the table.
				if !args[0]
					rs = @db.select(select_sql, [])
				else
					condition_sql, prepared_args_for_sql = create_condition_sql_stmt(args)
					rs = @db.select(select_sql + condition_sql, prepared_args_for_sql, *args)
				end

				# Transform the result.
				rs_format = transform_result(rs)
			end

			def insert(records)
				col_name_arr = []
				col_val_arr = []
				records_class = records.class

				if records_class <= Array
					records.each do |r|
						insert(r)
					end
				elsif records_class <= Hash or records_class <= Struct
					@columns.each do |col_info|
						col_name = col_info.column_name
						col_name_arr << col_name
						col_val_arr << records[col_name]
					end

					insert_sql = %Q{
						insert into
							#{@table_name}(#{col_name_arr.join(',')})
						values
							(#{ ('?' * col_val_arr.length).split('').join(',') })
					}

					@db.exec_stmt(insert_sql, *col_val_arr)
				end
			end

			def update(*args)
				col_name_arr = []
				val_arr = []

				if args[0].class <= Array
					args[0].each do |r|
						update(r)
					end
				elsif args[0].class <= Hash 
					if args.last.class == Hash and args.last[:set]
						update_info = args.pop[:set]
						sql_stmt_args = update_info.values
						condition_sql, prepared_args_for_sql = create_condition_sql_stmt(args)
						sql_stmt_args.concat(prepared_args_for_sql)
						update_sql = %Q{
							update #{@table_name} set
								#{update_info.keys.join('=?, ')}=?
							#{condition_sql}
						}

						@db.exec_stmt(update_sql, *sql_stmt_args)
					end
				elsif args[0].class <= Struct # Update one record
					record = args[0]

					# Only if the table have a primary key can the followed codes be executed.
					if !@primary_key_name_list.empty?
						@columns.each do |col_info|
							col_name = col_info.column_name
							col_name_arr << col_name
							val_arr << record[col_name]
						end

						pri_col_name_arr = []
						@primary_key_name_list.each do |col_name|
							pri_col_name_arr << col_name
							val_arr << record[col_name]
						end

						update_sql = %Q{
							update #{@table_name} set
								#{col_name_arr.join('=?, ')}=?
							where
								#{pri_col_name_arr.join('=? and ')}=?
						}

						@db.exec_stmt(update_sql, *val_arr)
					end
				end
			end

			def delete(*args)
				if args.empty?
					rs = @db.exec_stmt(@basic_delete_sql)
				elsif args[0].class <= Array
					args[0].each do |r|
						delete(r)
					end
				elsif args[0].class <= Struct
					record = args[0]

					# Only if the table have a primary key can the followed codes be executed.
					if !@primary_key_name_list.empty?
						val_arr = []
						pri_col_name_arr = []

						@primary_key_name_list.each do |col_name|
							pri_col_name_arr << col_name
							val_arr << record[col_name]
						end

						delete_sql = %Q{
							delete from 
								#{@table_name}
							where
								#{pri_col_name_arr.join('=? and ')}=?
						}

						@db.exec_stmt(delete_sql, *val_arr)
					end
				else
					condition_sql, prepared_args_for_sql = create_condition_sql_stmt(args)
					rs = @db.exec_stmt(@basic_delete_sql + condition_sql, *prepared_args_for_sql)
				end
			end

			def create_condition_sql_stmt(args)
				sql_stmt = ""
				prepared_args_for_sql = [] # This variable is used to store all arguments that are to be passed to the sql string.

				appendix = ""
				if !(args[0].class <= Integer) # Imply that there are some conditions in the statement.
					sql_stmt += " where "
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

					sql_stmt += " #{condition_sql} or "

					args.shift
				end

				sql_stmt += appendix

				[sql_stmt, prepared_args_for_sql]
			end

			def transform_result(rs)
				rs_format = []

				case @row_format
				when :hash, :bean
					rs.each do |r|
						h = (@row_format == :hash ? {} : new_record)
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
							
						# If the table have a single primary key:
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
