require_relative 'dbFactory.rb'

module Zombiehome

	class MysqlDBFactory < DBFactory
		def refresh_tables_views_list
			@tables_views_list = []
			select_and_handle(%Q{
				SELECT 
					* 
				FROM 
					information_schema.tables
				WHERE
					table_schema = "#{@schema}"
			}) do |r|
				@tables_views_list << r["TABLE_NAME"]
			end
		end

		def select(sql_stmt, args, *other_args)
			limit_str = ""
			other_str = ""

			if other_args[0].class <= Integer
				limit_str = "LIMIT #{other_args[0]}"
				if other_args[1].class <= Integer
					limit_str += ", #{other_args[1]}"
				end

				if other_args[2].class <= Hash
					other_args2 = other_args[2]

					group_args = other_args2[:g] || other_args2[:group_by]
					if group_args
						other_str += " GROUP BY #{group_args.join(',')} "
					end

					order_args = other_args2[:g] || other_args2[:order_by]
					if order_args
						other_str += " ORDER BY #{order_args.join(',')} "
					end
				end
			end
			sql_stmt += (other_str + limit_str)

			rs = super(sql_stmt, args)
		end	
	end
	
end

require_relative '../table/mysqlTable.rb'