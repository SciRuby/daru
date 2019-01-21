
require_relative 'benchmarker'

$:.unshift File.expand_path("../../../lib", __FILE__)

DF_SIZE_POW_10 = [2, 3, 4, 5, 6, 7]

DF_SIZE_POW_10.each do |df_size|
	puts "DataFrame of size : #{10**df_size} "
	Benchmarker.benchmark_create_df(10**df_size)
	Benchmarker.benchmark_mean()
	Benchmarker.benchmark_mode()
	Benchmarker.benchmark_median()
	Benchmarker.benchmark_sum()
	Benchmarker.benchmark_product()
	Benchmarker.benchmark_median_absolute_deviation()
	Benchmarker.benchmark_sum_of_squared_deviation()
	Benchmarker.benchmark_average_deviation_population()
	puts 
end

Benchmarker.result()

# Real times for vector size [10**2, 10**3,10**4,10**5,10**6] 

# Means => ["0.000059782999", "0.000039732000", "0.000049370999", "0.000053350000", "0.000069114000", "0.000059550001"]
# mode => ["0.000362311001", "0.000497481001", "0.000375471000", "0.000315499000", "0.000498609000", "0.000256725000"]
# median => ["0.000163064999", "0.000179371000", "0.000113426000", "0.000117927000", "0.000157335000", "0.000120525000"]
# sum => ["0.000028036000", "0.000106457000", "0.000024055000", "0.000025545000", "0.000035602000", "0.000027020000"]
# product => ["0.000023257000", "0.000037252000", "0.000021918000", "0.000022294000", "0.000033712000", "0.000022573000"]
# median_absolute_deviation => ["0.000228032000", "0.000427085000", "0.000212802001", "0.000227248000", "0.000321677000", "0.000218785000"]
# sum_of_squared_deviation => ["0.000048617000", "0.000063766000", "0.000039721001", "0.000120714000", "0.000052445000", "0.000040694000"]
# average_deviation_populationa => ["0.000117892000", "0.000167791000", "0.000102102000", "0.000105429001", "0.000140446000", "0.000159499999"]
# create df real time => ["0.001020248000", "0.010377509000", "0.120133259000", "0.988936126000", "10.624304956000", "160.231077512000"]