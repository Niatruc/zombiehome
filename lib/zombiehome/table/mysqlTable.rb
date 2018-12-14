require_relative 'table'
module Zombiehome

	class MysqlDBFactory
		class Table < DBFactory::Table
			def refresh_columns_info
				@columns = []
				@primary_key_name_list = []

				@db.select_and_handle(%Q{
					SELECT
						*
					FROM
						information_schema.columns
					WHERE
						table_name = '#{@table_name}'
				}) do |r|
					col = Column.new
					Column.members.each do |column_info_field|
						column_info_field_upper = column_info_field.to_s.upcase
						col[column_info_field] = r[column_info_field_upper] || "(null)"

					end
					@columns << col
				end

				# Record the primary key of the table.
				@columns.each do |col_info|
					if col_info.column_key == "PRI"
						@primary_key_name_list << col_info.column_name
					end
				end

				# p @primary_key_name_list
			end
		end
	end
end