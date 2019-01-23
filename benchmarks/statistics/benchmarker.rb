
require 'benchmark'

$:.unshift File.expand_path("../../../lib", __FILE__)

require 'daru'

class Benchmarker
	@df = Daru::DataFrame.new()
	@df_size = 0
	@result_mean = []
	@result_mode = []
	@result_median = []
	@result_sum = []
	@result_product = []
	@result_median_absolute_deviation = []
	@result_sum_of_squared_deviation = []
	@result_average_deviation_populationa = []
	@result_create_df = []

	class << self
		attr_accessor :df, :df_size, :result_mean,	:result_mode,
		:result_median,
		:result_sum,
		:result_product,
		:result_median_absolute_deviation,
		:result_sum_of_squared_deviation,
		:result_average_deviation_populationa,
		:result_create_df
	end

	def self.benchmark_mean()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector mean => ') do
		   		@df[0].mean
			end
			@result_mean.append("%1.20f" % report.real)
			# print "%1.20f" % report.real
		end
	end

	def self.benchmark_mode()
		
		bench = Benchmark.bm do |x|
			report =x.report('Vector mode => ') do
		   		@df[0].mode
			end
			@result_mode.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_median()
		
		bench = Benchmark.bm do |x|
			report =x.report('Vector median => ') do
		   		@df[0].median
			end
			@result_median.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_sum()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector sum => ') do
		   		@df[0].sum
			end
			@result_sum.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_product()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector product => ') do
		   		@df[0].product
			end
			@result_product.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_median_absolute_deviation()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector median_absolute_deviation => ') do
		   		@df[0].median_absolute_deviation
			end
			@result_median_absolute_deviation.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_sum_of_squared_deviation()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector sum_of_squared_deviation => ') do
		   		@df[0].sum_of_squared_deviation
			end
			@result_sum_of_squared_deviation.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_average_deviation_population()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector average_deviation_population => ') do
		   		@df[0].average_deviation_population
			end
			@result_average_deviation_populationa.append("%1.20f" % report.real)
		end	
	end

	def self.benchmark_create_df(size)
		bench = Benchmark.bm do |x|
			report = x.report('Create DataFrame of size :' + size.to_s + ' => ') do
				self.generate_df(size)
			end
			@result_create_df.append("%1.20f" % report.real)
		end
	end

	def self.generate_df(size)
		# for size * size dataframe
		# @df= Daru::DataFrame.new(
		# 	Array.new(size) { Array.new(size) { size*rand(1..9) }  }
		# )

		# creaating dataframe of size =  size * 2
		@df= Daru::DataFrame.new(
			Array.new(size) { Array.new(2) { 2*rand(1..9) }  }
		)
		@df_size = size
	end

	def self.result()
		puts 'Real times for vector size [10**2, 10**3,10**4,10**5,10**6] '
		puts 'Means => ', @result_mean.join(" | ")
		puts 'mode => ' , @result_mode.join(" | ")
		puts 'median => ' , @result_median.join(" | ")
		puts 'sum => ' , @result_sum.join(" | ")
		puts 'product => ' , @result_product.join(" | ")
		puts 'median_absolute_deviation => ' , @result_median_absolute_deviation.join(" | ")
		puts 'sum_of_squared_deviation => ' , @result_sum_of_squared_deviation.join(" | ")
		puts 'average_deviation_populationa => ' , @result_average_deviation_populationa.join(" | ")
		puts 'create df real time => ' , @result_create_df.join(" | ")
	end

	def self.result_with_size()
		puts 'Real times for vector size [10**2, 10**3,10**4,10**5,10**6] '

		self.print_array(@result_mean, 'MEAN')

		print_array(@result_mode, 'mode')

		print_array(@result_median, 'median')

		print_array(@result_sum, 'sum')

		print_array(@result_product, 'product')
		
		print_array(@result_median_absolute_deviation, 'median_absolute_deviation')

		print_array(@result_sum_of_squared_deviation, 'sum_of_squared_deviation')

		print_array(@result_average_deviation_populationa, 'average_deviation_populationa')

		print_array(@result_create_df, 'create df real time')
	end

	private

	def self.print_array(array, task)
		puts 
		puts "Method on DataFrame Vector (Vector access and apply method): **#{task}**"
		puts
		puts " | Number of rows | Real Time | "
		puts " |------------|------------| "
		array.each_with_index do |val, index|
			puts " | 10 ** #{index + 2} | #{val} | " 
		end
	end

end

