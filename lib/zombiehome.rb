require_relative "./zombiehome/version"
require_relative "../conf/required_libs"
require "yaml"


module Zombiehome
	# Your code goes here...
	LibAbsDir = File.dirname(__FILE__) + '/'

	CONFIG = {}
	config = ::YAML.load(File.open(LibAbsDir + "../conf/config.yml"))
	CONFIG.merge!(config)

	# Read the configuration item from the yml file that is specified in conf/config.yml
	CONFIG.merge!(::YAML.load(File.open(CONFIG["user_config_file_path"])))
	
	$debug = CONFIG["debug"]

	# Used to print debug messages when developing this project
	$pd = ->(*args) {
		if $debug
			args.each do |a|
				puts a
			end
		end
	}

	# Used to print debug messages when developing this project
	$raise = ->(msg) {
		Errno.send(:raise, "Zombiehome[#{Time.now}]: #{msg}")
	}
	
	["ext", "dbFactory"].each do |d|
		Dir.open("#{LibAbsDir}zombiehome/#{d}/").each do |f|
			if !(f =~ /^\./)
				require "#{LibAbsDir}zombiehome/#{d}/#{f}"
			end
		end
	end
end

# require_relative './zombiehome/dbFactory/dbFactory.rb'