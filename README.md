# Zombiehome

Thanks for giving an attention to this project. This project can be seen as a DSL for conveniently manipulating data in database in different types (Oracle, MySql, Hbase, etc.). You can use expression in Ruby syntax rather than SQL to accomplish daily database work such as CURD. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zombiehome'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zombiehome

## Setup
Modify the file `./conf/required_files` which will be loaded when `zombiehome` is loaded. Write codes that will load neccessary libraries here. Note that `zombiehome` is based on `DBI` library. For example, when you are on JRuby Platform and you want to manage a Mysql instance, then in this file you should add a line that will load your Mysql JDBC jar file:
```ruby
require '/home/u/mysql_jar/mysql-connector-java-5.1.43-bin.jar'
```

To connect to your database, you should write some configure items in a yml file seems like the follow:
```yml
type: "mysql"
url: "DBI:Jdbc:mysql://192.168.1.100/mydb?useSSL=false"
user: "root"
password: "toor"
schema: "mydb"
driver: "com.mysql.jdbc.Driver"
```
Then specify your file name in `./conf/config.yml` file:
```yml
user_config_file_path: "/home/u/conf/user config.yml"
```

Or else you could parse those configure items to `Zombiehome::DBFactory.create` method to create an functional instance.

## Usage
### In Codes
Step 1, create a new `Zombiehome::ServerFactory` instance:
```ruby
lh = Zombiehome::MysqlDBFactory.create({
	type: 'mysql',
	url: 'localhost:3306/test',
	user: 'root',
	psw: 'root',
})
lht = lh.tables
```

Step 2, perform CRUD actions. Suggest I have a mysql schema named as 'mySchema' and where there is a table called 'users', which is defined as follow:
```sql
create table users (
	id varchar(30) primary key,
	first_name varchar(100),
	last_name varchar(100),
	gender char(1),
	birthday date,
	address varchar(10),
	description varchar(10)
)
```
An example for reading records:
```ruby
# Select records from the table 'users', from the 1st to the 11th.
users_list = lht.users.select(1, 10)

# Select one row by primary key. If a table have a composite primary key, put the pk value into an array in the order of how they are written when creating the table, and then pass the array to the follow method.
me = lht.users.select(['00001', '00002'])  # table has a single primary key
me = lht.users.select([[1, '0'], [2, '0']])  # table has a composite primary key

# select 
# 	* 
# from 
# 	users 
# where 
# 	gender = '0' 
# 	and last_name in ('zhao', 'qian', 'sun', 'li')
# 	and birthday between '1990-01-01' and '2018-12-31'
# 	and address is not null
# 	first_name is like 'han%'
users = lht.users.select({
	gender: '0', 
	last_name: ['zhao', 'qian', 'sun', 'li'],
	birthday: '1990-01-01'..'2018-12-31',
	0 => "address is not null",
	1 => ["first_name is like ?", ["han%"]],
})

# If should add a `or` clause, then separate the criteria into two Hash instances
users = lht.users.select({
	birthday: '1990-01-01'..'2018-12-31',
}, {
	birthday: '1960-01-01'..'1980-01-01',
}) # means `birthday between '1990-01-01' and '2018-12-31' OR birthday between '1960-01-01' and '1980-01-01'`

```

In most case, a call to `select` method would return an array of beans, representing records from the related table.
```ruby
users.each do |user|
	puts(user.birthday) # invoke getter

	user.gender = 0 # invoke setter
end
```

As for insert/update/delete work:
```ruby
lht.users.insert(user)
lht.users.insert([user1, user2]) # insert a batch of records

lht.users.update(user)
lht.users.update([user1, user2]) # update a batch of records

lht.users.delete(user)
lht.users.delete(user.id) # delete record by primary key
lht.users.delete([user1, user2]) # delete a batch of records
```

Conditions can be used while doing update/delete work:
```ruby
# update users set description = 'He is a boy!' where gender = 0
lht.users.update({gender: 0}, set: {description: 'He is a boy!'})

# delete from users where gender = 0
lht.users.delete({gender: 0})
```
### In command line
Some command line completion functions have been implemented so that when you turn into command line, you can click TAB button to complete commands or names。

For instance, you have a Mysql database instance, where you have some tables as follow:  
![image](https://github.com/Niatruc/zombiehome/blob/master/pic/tables.jpg)

After executing `connnect` (or `c` for short) command to connect to your database, you can click `Tab` button to complete your datatbase's or tables' or other variables' or methods' names. As in the follow gif, I use `Tab` button to quickly refer to `users` table and query its records.
![image](https://github.com/Niatruc/zombiehome/blob/master/pic/completion1.gif)

You can use `cd` command to change the conversation's context. As follow shows, after turning into `db.tables.users` table's context, when typing `select` and enter, it will fetch records from `db.tables.users` table. And if you just type `cd` and enter, it will return to the top level context (which is the same as that context you are first in after lauching this program).
![image](https://github.com/Niatruc/zombiehome/blob/master/pic/completion2.gif)

Using conditions when query records will be like this:  
![image](https://github.com/Niatruc/zombiehome/blob/master/pic/condition1.gif)

## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Niatruc/zombiehome.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
