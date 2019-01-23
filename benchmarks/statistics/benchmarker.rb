
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
	@result_unique = []

	class << self
		attr_accessor :df, :df_size, :result_mean,	:result_mode,
		:result_median,
		:result_sum,
		:result_product,
		:result_median_absolute_deviation,
		:result_sum_of_squared_deviation,
		:result_average_deviation_populationa,
		:result_create_df,
		:result_unique
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

	def self.benchmark_unique()
		bench = Benchmark.bm do |x|
			report = x.report('return Unique elements => ') do
				@df[0].uniq			end
			@result_unique.append("%1.20f" % report.real)
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
		puts 'Unique elements => ', @result_unique.join(" | ")
	end

	def self.result_with_size()
		puts 'Real times for vector size [10 ** 2, 10 ** 3,10 ** 4,10 ** 5,10 ** 6] '

		self.print_array(@result_mean, 'MEAN')

		print_array(@result_mode, 'mode')

		print_array(@result_median, 'median')

		print_array(@result_sum, 'sum')

		print_array(@result_product, 'product')
		
		print_array(@result_median_absolute_deviation, 'median_absolute_deviation')

		print_array(@result_sum_of_squared_deviation, 'sum_of_squared_deviation')

		print_array(@result_average_deviation_populationa, 'average_deviation_populationa')

		print_array(@result_create_df, 'create df real time')
		print_array(@result_unique, 'return Unique elements')
	end

	def self.result_compare()
		puts 'Real times for vector size [10 ** 2, 10 ** 3,10 ** 4,10 ** 5,10 ** 6] '
		puts 'Comparing with Pandas and NumPy'
		# latest (jan 2019) Pandans and NumPy benchmark:  https://github.com/Shekharrajak/Fast-Pandas/tree/shekhar_dev
		pandas_mean = ['0.00002460720880008011', '0.00002646757190013886', '0.00004172052699868800', '0.00015707365499838488', '0.00156584847998601610', '0.01197717989998636767', '0.12047314550000010058'] 
		numpy_mean = ['0.00002989581900001212', '0.00003186123070008762', '0.00004564955699970596', '0.00015398673500021686', '0.00131619396001042338', '0.01254011160017398652', '0.12039573559995915553'] 

		self.print_array_compare(@result_mean, 'MEAN', pandas_mean, numpy_mean)

		# TODO
		# print_array_compare(@result_mode, 'mode')

		pandas_median = ['0.00002452081701998395', '0.00002761571300001378', '0.00013392778345998522', '0.00093059150948996826', '0.01047319806000086839', '0.11693990839001344728', '1.27000799899906269275'] 
		numpy_median = ['0.00002926640069999848', '0.00003277218365001318', '0.00011260383452001407', '0.00101361991900001162', '0.00969792961999701303', '0.12528731213002175515', '1.23991956400277558714'] 
		print_array_compare(@result_median, 'median', pandas_median, numpy_median)

		pandas_sum = ['0.00005380277499971271', '0.00006364958799968007', '0.00009241857799861464', '0.00041669552999883309', '0.00496692907003307496', '0.06522532849994604198', '0.68193949160013289656'] 
		numpy_sum = ['0.00006421745570005442', '0.00006488183500005107', '0.00012525086099776672', '0.00063505067000005507', '0.00576831682999909365', '0.07603158420024555553', '0.68379156730006795950'] 
		print_array_compare(@result_sum, 'sum', pandas_sum, numpy_sum)

		pandas_prod = ['0.00004321602870004426', '0.00004952814159987611', '0.00007920588500201119', '0.00037602675800008003', '0.00343111220001446771', '0.03398789710008713605', '0.35793153200211236253'] 
		numpy_prod = ['0.00005185432299986132', '0.00005675383920024615', '0.00008350405899909674', '0.00039026842300154388', '0.00372708013001101781', '0.03601436539975111373', '0.35189221399923553690'] 
		print_array_compare(@result_product, 'product', pandas_prod,  numpy_prod)
		
		# TODO
		# print_array_compare(@result_median_absolute_deviation, 'median_absolute_deviation')
		# print_array_compare(@result_sum_of_squared_deviation, 'sum_of_squared_deviation')
		# print_array_compare(@result_average_deviation_populationa, 'average_deviation_populationa')

		pandas_dataframe_avg_time  =  ['0.00021143017630020040', '0.00020791667079975013', '0.00021926641200116137', '0.00021049363799829733', '0.00028836761001002739', '0.00028369350002321880', '0.00490571899717906490']
		print_array_compare(@result_create_df, 'create df real time', pandas_dataframe_avg_time, [1,1,1,1,1,1])

		pandas_unique = ['0.00003281123619999562', '0.00004384756529980222', '0.00014993138900172199', '0.00111055827999734908', '0.02723045833001378965', '0.35414526560016384993', '6.69910524100123438984'] 
		numpy_unique = ['0.00001474316399981035', '0.00004764209610002581', '0.00059559319099935235', '0.00686007325100217689', '0.07511945111000387088', '0.90684124439976587784', '10.35867670299921883270'] 
		print_array_compare(@result_unique, 'return Unique elements', pandas_unique, numpy_unique)

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

	def self.print_array_compare(array, task, compare_with_array1, compare_with_array2)
		puts 
		puts "Method on DataFrame Vector (Vector access and apply method): **#{task}**"
		puts
		puts " | Number of rows | Real Time | Pandas avg time | daru/pandas | NumPy avg time | daru/numpy | "
		puts " |------------|------------|------------|------------|------------|------------| "
		array.each_with_index do |val, index|
			puts " | 10 ** #{index + 2} | #{val} | #{compare_with_array1[index]} | #{Float(val)/Float(compare_with_array1[index])} | #{compare_with_array2[index]} | #{Float(val)/Float(compare_with_array2[index])} |" 
		end
	end

end

