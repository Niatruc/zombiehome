# require_relative '../../zombiehome.rb'
require_relative '../table/table.rb'
require_relative '../dbiWrapper.rb'

module Zombiehome
	class DBFactory
		pd CONFIG
		include DbiWrapper

		DBType2DBFactoryName = {
			"mysql" => "MysqlDBFactory",
			"oracle" => "OracleDBFactory",
		}

		class << self

			def create(*args)
				# db = new
				config = args[0] || {}
				driver_class_str = config[:driver] || CONFIG["driver"]

				db_type = config[:type] || CONFIG["type"]
				if !DBType2DBFactoryName[db_type]
					$raise.("unknown database type: #{db_type}")
				end
				db = eval(%Q{#{DBType2DBFactoryName[db_type]}.new})

				url = config[:url] || CONFIG["url"]
				user = config[:user] || CONFIG["user"]
				password = config[:password] || CONFIG["password"]
				schema = config[:driver] || CONFIG["schema"]

				db.connect(
					url,
					user,
					password,
					*[{"driver" => (driver_class_str if driver_class_str)}]
				)

				db.instance_eval do
					@schema = schema
					@url = url
					@user = user
					@password = password
					@tables_views_list = @dbh.tables

					@table_pool = {}
					# def @table_pool.to_s
					# 	"table_pool"
					# end
					# def @table_pool.inspect
					# 	"table_pool"
					# end

					init_tables
				end

				db
			end
		end

		attr_accessor :table_pool, :table_pool_size, :tables_views_list, :tables

		def refresh_tables_views_list
			
		end

		def methods
			%i{
				tables
			}
		end

		def to_s
			%Q{
				schema: #{@schema}
				url: #{@url}
				user: #{@user}
				password: #{@password}
			}
		end

		private

		def init_tables
			@tables = BasicObject.new

			class << @tables
				def is_zbh_tables!
					true
				end

				def tables_list!
					@db.tables_views_list
				end

				def binding!
					::Kernel.binding
				end

				alias :instance_eval! :instance_exec

				def method_missing(table_name, *args, &blk)
					# When retreving a table, the code below would be executed
					table_name = table_name.to_s
					if !@db.tables_views_list.include?(table_name)
						$raise.("Table or view '#{table_name}' is undefined.")
					else
						table = @db.table_pool[table_name]
						if !table
							table = @db.class::Table.create_table_dao({
								db: @db,
								table_name: table_name
							})
							@db.table_pool[table_name] = table
						end
						table
					end
				end

				if $debug
					def to_s
						%w{
							#<#<Zombiehome::DBFactory>@tables: #{@id}>
							instance_variables:
								@db: #{@db}
								@id: #{@id}
						}
					end
				else
					def to_s
						
					end
				end

			end
			
			db = self
			@tables.instance_eval do 
				@db = db
				@id = __id__
				undef :instance_eval, :instance_exec, :__id__, :__send__
			end
		end
	end
	
end