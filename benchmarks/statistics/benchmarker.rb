
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
			@result_mean.append("%1.12f" % report.real)
			# print "%1.12f" % report.real
		end
	end

	def self.benchmark_mode()
		
		bench = Benchmark.bm do |x|
			report =x.report('Vector mode => ') do
		   		@df[0].mode
			end
			@result_mode.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_median()
		
		bench = Benchmark.bm do |x|
			report =x.report('Vector median => ') do
		   		@df[0].median
			end
			@result_median.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_sum()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector sum => ') do
		   		@df[0].sum
			end
			@result_sum.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_product()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector product => ') do
		   		@df[0].product
			end
			@result_product.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_median_absolute_deviation()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector median_absolute_deviation => ') do
		   		@df[0].median_absolute_deviation
			end
			@result_median_absolute_deviation.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_sum_of_squared_deviation()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector sum_of_squared_deviation => ') do
		   		@df[0].sum_of_squared_deviation
			end
			@result_sum_of_squared_deviation.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_average_deviation_population()
		
		bench = Benchmark.bm do |x|
			report = x.report('Vector average_deviation_population => ') do
		   		@df[0].average_deviation_population
			end
			@result_average_deviation_populationa.append("%1.12f" % report.real)
		end	
	end

	def self.benchmark_create_df(size)
		bench = Benchmark.bm do |x|
			report = x.report('Create DataFrame of size :' + size.to_s + ' => ') do
				self.generate_df(size)
			end
			@result_create_df.append("%1.12f" % report.real)
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
		print 'Means => ', @result_mean.to_a
		puts
		print 'mode => ' , @result_mode.to_a
		puts
		print 'median => ' , @result_median.to_a
		puts
		print 'sum => ' , @result_sum.to_a
		puts
		print 'product => ' , @result_product.to_a
		puts
		print 'median_absolute_deviation => ' , @result_median_absolute_deviation.to_a
		puts
		print 'sum_of_squared_deviation => ' , @result_sum_of_squared_deviation.to_a
		puts
		print 'average_deviation_populationa => ' , @result_average_deviation_populationa.to_a
		puts
		print 'create df real time => ' , @result_create_df.to_a
	end
end

