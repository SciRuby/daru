# 0.3 (30 May 2020)
* Major Enhacements
  - Remove official support for Ruby < 2.5.1. Now we only test with 2.5.1 and 2.7.1. (@v0dro)
  - Make nmatrix and gsl optional dependencies for testing. (@v0dro)
  - Update sqlite, activerecord, nokogiri, packable, rake dependencies. (@v0dro)
  - Remove runtime dependency on backports. (@v0dro)
  - Add `Daru::Vector#match and Daru::Vector#apply_where` methods (@athityakumar).
  - Add support for options to the `Daru` module. Adds a separate module `Daru::Configuration` that
  can hold data for overall configuration of daru's execution. (@kojix2)
* Minor Enhancements
  - Add new `DataFrame#insert_vector` method. (@cyrillefr)
  - Add `Vector#last`. (@kojix2)
  - Add `DataFrame#rename_vectors!`. (@neumanrq)
  - Refactor `GroupBy#apply_method`. (@paisible-wanderer)
  - Auto-adjust header parameters when printing to terminal. (@ncs1)
  - Infer offsets of timeseries automatically when they are a natural number multiple of seconds. (@jpaulgs)

# 0.2.2 (8 August 2019)

* Minor Enhancements
  - DataFrame#set_index can take column name array, which results in multi-index  https://github.com/SciRuby/daru/pull/471 (by @Yuki-Inoue)
  - implements DataFrame#reset_index https://github.com/SciRuby/daru/pull/473  (by @Yuki-Inoue)
  - Make DataFrame.from_activerecord faster https://github.com/SciRuby/daru/pull/464 (by @paisible-wanderer )
  - Added access_row_tuples_by_indexs method https://github.com/SciRuby/daru/pull/463 (by @Prakriti-nith )

* Fixes
  - Fix reindex vector on argument error https://github.com/SciRuby/daru/pull/470 (by @Yuki-Inoue)
  - Optimize aggregation https://github.com/SciRuby/daru/pull/464 (by @paisible-wanderer)
  - Index#dup should copy reference to name too https://github.com/SciRuby/daru/pull/477 (by @Yuki-Inoue)
  - Should support bundler version 2.x.x https://github.com/SciRuby/daru/pull/483/ (by @Shekharrajak )
  - fix table style  https://github.com/SciRuby/daru/pull/489 (by @kojix2 )

# 0.2.1 (02 July 2018)

* Minor Enhancements
  - Allow pasing singular Symbol to CSV converters option (@takkanm)
  - Support calling GroupBy#each_group w/o blocks (@hibariya)
  - Refactor grouping and aggregation (@paisible-wanderer)
  - Add String Converter to Daru::IO::CSV::CONVERTERS (@takkanm)
  - Fix annoying missing libraries warning
  - Remove post-install message (nice yet useless)

* Fixes
  - Fix group_by for DataFrame with single row (@baarkerlounger)
  - `#rolling_fillna!` bugfixes on `Daru::Vector` and `Daru::DataFrame` (@mhammiche)
  - Fixes `#include?` on multiindex (@rohitner)

# 0.2.0 (31 October 2017)
* Major Enhancements
  - Add `DataFrame#which` query DSL (experimental! @rainchen)
  - Add `DataFrame/Vector#rolling_fillna` (@baarkerlounger)
  - Add `GroupBy#aggregate` (@shekharrajak)
  - Add `DataFrame#uniq` (@baarkerlounger)

* Minor Enhancements
  - Allow `Vector#count` to be called without param for category type Vector (@rainchen)
  - Add option to `DataFrame#vector_sum` to skip nils (@parthm)
  - Add installation instructions to README.md (@koishimasato)
  - Add release policy documentation (@baarkerlounger)
  - Set index as DataFrame's default x axis for nyaplot (@matugm)

* Fixes
  - Fix `DataFrame/Vector#to_s` when name is a symbol (@baarkerlounger)
  - Force `Vector#proportions` to return float (@rainchen)
  - `DataFrame#new` creates empty DataFrame when given empty hash (@parthm)
  - Remove unnecessary backports dependencies (@zverok)
  - Specify minimum packable dependency (@zverok)
  - Preserve key/column order when creating DataFrame from hash (@baarkerlounger)
  - Fix `DataFrame#add_row` for DF with multi-index (@zverok)
  - Fix `Vector#min, `#max`, `#index_of_min`, `#index_of_max` (0.1.6 regression) (@athityakumar)
  - Integrate yard-junk into CI (@rohitner)
  - Remove Travis spec restriction (@zverok)
  - Fix tuple sorting for DataFrames with nils (@baarkerlounger)
  - Fix merge on index dropping default index (@rohitner)

# 0.1.6 (04 August 2017)
* Major Enhancements
  - Add support for reading HTML tables into DataFrames (@athityakumar)
  - Add support for importing remote CSVs (@athityakumar, @anshuman23)
  - Allow named indexes (@Shekharrajak)
  - DataFrame GroupBy returns MultiIndex DataFrame (@Shekharrajak)
  - Add new functions to Vector: max, min, index_of_max, index_of_min, max_by, min_by, index_of_max_by, index_of_min_by (@athityakumar)
  - Add summary to DataFrame and Vector without reportbuilder (@ananyo2012)
  - Add support for missing data for where clause (@athityakumar)

* Minor Enhancements
  - Allow inserting or updating DataFrame vectors with single values (@baarkerlounger)
  - Add a boolean converter to the CSV importer (@baarkerlounger)
  - Fix documentation of replace_values method (@kojix2)
  - Improve HTML table code of DataFrame and Vector (@Shekharrajak  )
  - Support CSV files with empty rows (@baarkerlounger)
  - Better DataFrame and Vector to_s methods (@baarkerlounger)
  - Add support for histogram to Vector moving average convergence-divergence (@parthm)
  - Add support for negative arguments to Vector.lag (@parthm)
  - Return Nyaplot instance instead of nil for Nyaplot Vector, Category and DataFrame (@Shekharrajak)
  - Add global configurable error stream which allows error stream to be silenced (@sivagollapalli)
  - Rubocop update and cleanup (@zverok)
  - Improve performance of DataFrame covariance (@genya0407)
  - Index [] to only take index value as argument (@ananyo2012)
  - Better error raised when Vector is missing from DataFrame (@sivagollapalli)
  - Add default order for DataFrame (@athityakumar)
  - Add is_values to Index (@Shekharrajak)
  - Improve spec style in IO/SQL data source spec (@dshvimer)
  - Open SQLite databases by bath (@dshvimer)
  - Remove unnecessary whitespace (@Shekharrajak)
  - Remove the .svg from Travis CI build link (@athityakumar)
  - Fix Travis CI icon in README (@athityakumar)
  - Replace is_nil?, not_nil? with is_values (@lokeshh)
  - Update contributing documentation (@v0dro)

* Fixes
  - Fix missing axis labels for categorized scatter plot with Gruff (@xprazak2)
  - Fix NMatrix Vector initialization when Vector has nils and no nm_type is given (@baarkerlounger)
  - Fix head/tail methods on DataFrames with DateTime indexes and on Vector_at splat calls (@baarkerlounger)
  - Fix empty DateTime Index (@zverok)
  - Fix where clause when data contains missing/undefined values (@Shekharrajak)
  - Fix apply_scalar_operator spec (@athityakumar)
  - Change nil check to respond_to operator check for apply_scalar_operator (@athityakumar)
  - Make where compatible with is_values (@athityakumar)
  - Fix vector is_values method (@athityakumar)


# 0.1.5 (30 January 2017)
* Major Enhancements
  - Add Daru::Vector#group_by (@lokeshh).
  - Add rspec-guard to run tests automatically (@lokeshh).
  - Remove Daru::DataFrame implicit Hash method since Dataframes are not implicit hashes and having an implicit converter can introduce unwanted side effects. (@gnilrets)
  - Add `Daru::DataFrame#union`. (Tim)

* Minor Enhancements
  - Added a join indicator. (@gnilrets)
  - Support an enumerable value as an index of a vector. (Yuichiro Kaneko)
  - Add test case for `NegativeDateOffset`. (Yuichiro Kaneko)
  - Add test case for `#on_offset?`. (Yuichiro Kaneko)
  - `NegativeDateOffset#-` returns `DateOffset`. (Yuichiro Kaneko)
  - Make `Vector#resort_index` private because its only use was for internal usage in `Vector#sort`. (Yuichiro Kaneko)
  - Add `DataFrame#order=` method to reorder vectors in a dataframe. (@lokeshh)
  - Use `Integer` instead of `Fixnum` throughout the gem. (Yuichiro Kaneko)
  - Improve error message of `Daru::Vector#index=`. (@lokeshh)
  - Deprecate `freqs` and make `frequencies` return a `Daru::Vector`. (@lokeshh)
  - `DataFrame#access_row` with integer index. (Yusuke Sangenya)
  - Add method alias for comparison operator. (Yusuke Sangenya)
  - Update Nokogiri version. (Yusuke Sangenya)
  - Return `Daru::Vector` for multiple modal values for `Daru::Vector#mode`. (@baarkerlounger)

* Fixes
  - Fix many to one joins. The prior version was shifting values in the left dataframe before checking whether values in the right dataframe should be shifted.  They both need to be checked at the same time before shifting either. (@gnilrets)
  - Support formatting empty dataframes. They were returning an error before. (@gnilrets)
  - method_missing in Daru::DataFrame would not detect the correct vector if it was a String. Fixed that. (@lokeshh)
  - Fix docs of contrast_code to specify that the default value is false. (@v0dro)
  - Fix occurence of SystemStackError due to faulty argument passing to Array#values_at. (@v0dro)
  - Fix `DataFrame#pivot_table` regression that raised an ArgumentError if the `:index` option was not specified. (@zverok)
  - Fix `DateFrame.rows` to accept empty argument. (@zverok)
  - Fix bug with false values on dataframe create. DataFrame from an Array of hashes wasn't being created properly when some of the values were `false`. (@gnilrets)
  - Fix `Vector#reorder!` method. (Yusuke Sangenya)
  - Fix `DataFrame#group_by` for numeric indexes. (@zverok)
  - Make `DataFrame#index=` accept only `Daru::Index`. (Yusuke Sangenya)
  - `DataFrame#vectors=` now changes the name of vectors contained in the internal `@data` variable. (Yusuke Sangenya)


# 0.1.4.1 (20 August 2016)
* Fixes
  - Turns out that removing the dependencies did not load a few libraries from the Ruby standard library when daru is deployed on a fresh system. This release fixes that by adding extra require calls.

# 0.1.4 (19 August 2016)

* Major Enhancements
  - Added new dependency 'backports' to support #to_h in Ruby 2.0. (@lokeshh)
  - Greatly improve code test coverage. (@zverok)
  - Greatly refactor code and make some methods faster, smaller and more readable. (@zverok)
  - Add support for categorical data with different coding schemes and several methods for in built categorical data support. Add a new index 'Daru::CategoricalIndex'. (@lokeshh)
  - Removed runtime dependencies on 'spreadsheet' and 'reportbuilder'. They are now loaded if the libraries are already present in the system. (@v0dro)

* Minor enhancements
  - Update SqlDataSource to improve the performance of DataFrame.from_sql. (@dansbits)
  - Remove default DataFrame name. Now DataFrames will no name by default. (@zverok)
  - Better looking #inspect for Vector and DataFrame. (@zverok)
  - Better looking #to_html for Vector and DataFrame. Also better #to_html for MultiIndex. (@zverok)
  - Remove monkey patching on Array and add those methods to Daru::ArrayHelper. (@zverok)
  - Add a rake task for running RSpec for every Ruby version with a single command. (@lokeshh)
  - Add rake tasks for easily setting up and testing test harness. (@lokeshh)
  - Added `Daru::Vector#to_nmatrix`.
  - Remove the 'metadata' feature introduced in v0.1.3. (@gnilrets)
  - Added `DataFrame#to_df` and `Vector#to_df`. (@gnilrets)

* Fixes
  - DataFrame#clone preserves order and name. (@wlevine)
  - Vector#where preserves name. (@v0dro)
  - Fix bug in DataFrame#pivot_table that prevented anything other than Array or Symbol to be specified in the :values option. (@v0dro)
  - Daru::Index#each returns an Enumerator if block is not specified. (@v0dro)
  - Fixes bug where joins failed when nils were in join keys. (@gnilrets)
  - DataFrame#merge now preserves the vector name type when merging. (@lokeshh)

* Deprecations
  - Remove methods DataFrame#vector and DataFrame#column. (@zverok)
  - Remove the missing_values feature of daru. The only values that are now treated as 'missing' are `nil` and `Float::NAN`. (@lokeshh)

# 0.1.3.1 (12 May 2016)

* Fixes
    - Fixed small error with usage of newly introduced #each_with_object (@v0dro).

# 0.1.3 (May 2016)

* Enhancements
    - Proper error handling for case where an index specified by the user is not actually present in the DataFrame/Vector (@lokeshh).
    - DataFrame CSV writer function will now supress headers when passing headers: false (@gnilrets).
    - Refactor Index and MultiIndex so that a Vector or DataFrame can access the actual index number without having to check the exact type of index every time (@lokeshh).
    - Refactor `Vector#[]=` to not use conditionals (@lokeshh).
    - Custom `#dup` method for `Daru::DateTimeIndex` (@Deepakkoli93).
    - Massive performance boost to Vector and DataFrame sorting by using in-built Array#sort and removing previous hand-made sort (@lokeshh).
    - Handle nils in sorting for Vectors and DataFrame (@lokeshh, @gnilrets).
    - Add #describe function for Vectors (@shahsaurabh0605).
    - Adds support for concatenating dataframes that don't share all the same vectors (@gnilrets).
    - Massive performance enhancement for joins using the sorted merge method (@gnilrets).
    - New statistics methods and tests for DataFrame (@shahsaurabh0605).
    - Add explicit conversion to hash for DataFrame (DataFrame#to_h, Vector#to_h) and remove implicit conversion to hash (DataFrame#to_hash, Vector#to_hash) (@gnilrets).
    - Add `DataFrame#rename_vectors` for simplifying renaming of vectors in DataFrame (@gnilrets).
    - MultiIndex raises error on accessing an invalid index (@shreyanshd).
    - Order columns as given in the CSV file when reading into a DataFrame from CSV using `DataFrame.from_csv` (@lokeshh).
    - Add `Vector#percent_change` and `DataFrame#percent_change` (@shahsaurabh0605).
    - Faster `DataFrame#filter_rows` (@lokeshh).
    - Added `Vector#emv` for calculating exponential moving variance of Vector (@shahsaurabh0605).
    - Add support for associating metadata with a Vector or DataFrame using the :metadata option (@gnilrets).
    - Add `Vector#emsd` for calculating exponential moving standard deviation of Vector (@shahsaurabh0605).
    - Sample and population covariance functions for Vector (@shahsaurabh0605).
    - Improve `DataFrame#dup` performance (@gnilrets).
    - Add `Daru::DataFrame::Core::GroupBy#reduce` for reducing groups by passing a block (@gnilrets).
    - Add rubocop as development dependency and make changes suggested by it to conform to the Ruby Style Guide (@zverok).
    - Allow Daru::Index to be initialized by a Range (@lokeshh).
* Fixes
    - Fix conflict with narray that caused namespace clashes with nmatrix in case both narray and nmatrix were installed on the user's system (@lokeshh).
    - Fix bug with dataframe concatenation that caused modifying the arrays that
    compose the vectors in the original dataframes (@gnilrets).
    - Fix an error where the Vectors in an empty DataFrame would not be assigned correct names (@lokeshh).
    - Correct spelling mistakes and fix broken links in README (@lokeshh).
    - Fix bug in Vector#mode (@sunshineyyy).
    - Fix `Vector#index_of` method to handle dtype :array differently (@lokeshh).
    - Fix `DateTimeIndex#include?` method since it was raising an exception when index not found. It returns false now (@Phitherek).
    - Handle nils in group_by keys (@gnilrets).
    - Handle nils for statistics methods in Vector and DataFrame for :array and :gsl data (@lokeshh).
    - Fix `DataFrame#clone` when no arguments have been passed to it (@lokeshh).
    - Fix bug when joining empty dataframes (@gnilrets).


# 0.1.2

* Enhancements
    - New method `DataFrame.from_activerecord` for importing data sets from ActiveRecord. (by @mrkn)
    - Better importing of data from SQL databases by extracting that functionality into a separate class called `Daru::IO::SqlDataSource` (by @mrkn).
    - Faster algorithm for performing inner joins by using the bloomfilter-rb gem. Available only for MRI. (by Peter Tung)
    - Added exception `SizeError` (by Peter Tung).
    - Removed outdated dependencies and build scripts, updated existing dependencies.
    - Ability to sort a Daru::Vector with nils present (by @gnilrets)

* Fixes
    - Fix column creation for `Dataframe.from_sql` (by @dansbits).
    - group_by can now be performed on DataFrames with nils (@gnilrets).
    - Bug fix for DataFrame Vectors not duplicating when calling `DataFrame#dup` (by @gnilrets).
    - Bug fix when concantenating DataFrames (by @gnilrets)
    - Handling improper arguments to `Daru::Vector#[]` (by @lokeshh)
    - Resolve narray conflict by using the latest nmatrix require methods (by @lokeshh)

# 0.1.1

* Enhancements
    - Added a new class Daru::Offsets for providing a uniform API to jump between dates.
    - Added benchmarking scripts
    - Added a new Arel-like querying syntax for Vector and DataFrame. This will allow faster and more intuitive lookup of data than using loops such as filter.
    - Vector
        - #concat now compulsorily requires a second index argument.
        - Added new method #index= to change the index directly.
        - Added basic functions for rolling statistics - mean, std, count, etc.
        - Added cumulative sum function.
        - Added #keep_if.
        - Added #count_values.
    - Indexing
        - Changed Index so that it now accepts all sorts of data (not restricted to only Symbols as it was previously).
        - Re wrote MultiIndex in levels and labels form so that its faster and more accomodative of different kinds of index levels.
        - Changed .new to return appropriate index object based on data passed.
        - Added .from_tuple and .from_array methods to MultiIndex.
        - Added union and intersection behaviour to Index and MultiIndex.
        - Added a new index, DateTimeIndex for indexing with time-based data.
        - Optimized range search for Index.
    - DataFrame
        - Removed the DataFrameByVector class and the #vector function. Now only
        way to access a Vector in a DF is by using the #[] operator.
        - Added new method #index= and #vectors= for changing row and column indexes directly.
        - Optimized Vector value setting and retreival.
        - Added inner, outer, left outer and right outer joins with the #join method.
        - Added #set_index.
* Changes
    - Removed the + operator overload from Index and replaced in with union.
    - Removed the second 'values' argument from Daru::Index because it's redundant.
    - Changed behaviour of Vector#reindex and DataFrame#reindex and #reindex_vectors to preserve indexing of original data when possible.
* Fixes
    - Fixed DataFrame#delete_row and Vector#delete_if.
    - Fixed Vector#rename.

# 0.1.0

* Fixes
    - Update documentation and fix it in other places.
    - Fix Vector#sum_of_squares and #ranked.
    - Fixed some tests that were giving RSpec warnings
    - Fixed a bug where nyaplot not being present would raise a warning.
    - Fixed a bug in DataFrame row assignment.
* Enhancements
    - Wrote a proper .travis.yml
    - Added optional GSL dependency gsl-nmatrix
    - Added Marshalling and unMarshalling capabilities to Vector, Index and DataFrame.
    - Added new method Daru::IO.load for loading data from files by marshalling.
    - Lots of documentation and new notebooks.
    - Added data loading and writing from and to CSV, Excel, plain text and SQL databases.
    - Daru::DataFrame and Vector have now completely replaced Statsample::Dataset and Vector.
    - Vector
        - #center
        - #standardize
        - #vector_percentile
        - Added a new wrapper class Daru::Accessors::GSLWrapper for wrapping around GSL::Vector, which works similarly to NMatrixWrapper or ArrayWrapper.
        - Added a host of statistical methods to GSLWrapper in Daru::Accessors::GSLStatistics that call the relevant GSL::Vector functions for super-fast C level computations.
        - More stats functions - #vector_standardized_compute, #vector_centered_compute, #sample_with_replacement, #sample_without_replacement
        - #only_valid for creating a Vector with only non-nil data.
        - #only_missing for creating a Vector of only missing data.
        - #only_numeric to create Vector of only numerical data.
        - Ported many Statsample::Vector stat methods to Daru::Vector. These are: #percentile, #factors, etc.
        - Added .new_with_size for creating vectors by specifying a size for the
        vector and a block for generating values.
        - Added Vector#verify, #recode! and #recode.
        - Added #save, #jackknife and #bootstrap.
        - Added #missing_values= that will allow setting values for treating data as 'missing'.
        - Added #split_by_separator, #split_by_separator_freq and #splitted.
        - Added #reset_index!
        - Added #any? and #all?
        - Added #db_type for guessing the type of SQL type contained in the vector.
        - Added and tested plotting support for histogram and box plot.
    - DataFrame
        - #dup_only_valid
        - #clone, #clone_only_valid, #clone_structure
        - #[]= does not clone the vector if it has the same index as the DataFrame.
        - Added a :clone option to initialize that will not clone Daru::Vectors passed into the constructor.
        - Added #save.
        - Added #only_numerics.
        - Added better iterators and changed some behaviour of previous ones to make them more ruby-like. New iterators are #map, #map!, #each, #recode and #collect.
        - Added #vector_sum and #vector_mean.
        - Added #to_gsl to convert to GSL::Matrix.
        - Added #has_missing_data? and #missing_values_rows.
        - Added #compute and #verify.
        - Added .crosstab_by_assignation to generate data frame from row, column and value vectors.
        - Added #filter_vector.
        - Added #standardize and added argument option to #dup.
        - Added #any? and #all? for vector and row axis.
        - Better creation of empty data frames.
        - Added #merge, #one_to_many, #add_vectors_by_split_recode
        - Added constant SPLIT_TOKEN and methods #add_vectors_by_split, .[], #summary.
        - Added #bootstrap.
        - Added a #filter method to wrap around #filter_vectors and #filter_rows.
        - Greatly improved plotting function.
    - Added a lazy update feature that will allow users to delay updating the missing positions index until the last possible moment.
    - Added interoperaility with rserve client which makes it possible to change daru data to R data and perform computation there.
* Changes
    - Changes Vector#nil_positions to Vector#missing_positions so that future changes for accomodating different values for missing data can be made easily.
    - Changed History.txt to History.md


# 0.0.5

* Easy accessors for some methods
* Faster CSV loading.
* Changed vector #is_valid? to #exists?
* Revamped dtype specifiers for Vector. Now specify :array/:nmatrix for changing underlying data implementation. Specigfy nm\_dtype for specifying the data type of the NMatrix object.
* #sort for Vector. Quick sort algorithm with preservation of original indexes.
* Removed #re\_index and #to\_index from Daru::Index.
* Ability to change the index of Vector and DataFrame with #reindex/#reindex!.
* Multi-level #sort! and #sort for DataFrames. Preserves indexing.
* All vector statistics now work with NMatrix as the underlying data type.
* Vectors keep a record of all positions with nils with #nil\_positions.
* Know whether a position has nils or not with #is_nil?
* Added #clone_structure to Vector for cloning only the index and structure or a vector.
* Figure out the type of data using #type. Running thru the data to determine its type is delayed till the last possible moment.
* Added arithmetic operations between data frame and scalars or other data frames.
* Added #map_vectors!.
* Create a DataFrame from Array of Arrays and Array of Vectors.
* Refactored DataFrame.rows and the  DataFrame constructor.
* Added hierarchial indexing to Vector and DataFrame with MultiIndex.
* Convert DataFrame to ruby Matrix or NMatrix with #to\_matrix and #to\_nmatrix.
* Added #group_by to DataFrame for grouping rows according to elements in a given column. Works similar to SQL GROUP BY, only much simpler.
* Added new class Daru::Core::GroupBy for supporting various grouping methods like #head, #tail, #get_group, #size, #count, #mean, #std, #min, #max.
* Tranpose indexed/multi-indexed DataFrame with #transpose.
* Convert Daru::Vector to horizontal or vertical Ruby Matrix with #to_matrix.
* Added shortcut to DataFrame to allow access of vectors by using only #[] instead of calling #vector or *[vector_names, :vector]*.
* Added DSL for Vector and DataFrame plotting with nyaplot. Can now grab the underlying Nyaplot::Plot and Nyaplot::Diagram object for performing different operations. Only need to supply parameters for the initial creation of the diagram.
* Added #pivot_table to DataFrame for reducing and aggregating data to generate a quick summary.
* Added #shape to DataFrame for knowing the numbers of rows and columns in a DataFrame.
* Added statistics methods #mean, #std, #max, #min, #count, #product, #sum to DataFrame.
* Added #describe to DataFrame for producing multiple statistics data of numerical vectors in one shot.
* Monkey patched Ruby Matrix to include #elementwise_division.
* Added #covariance to calculate the covariance between numbers of a DataFrame and #correlation to calculate correlation.
* Enumerators return Enumerator objects if there is no block.

# 0.0.4
* Added wrappers for Array, NMatrix and MDArray such that the external implementation is completely transparent of the data type being used internally.
* Added statistics methods for vectors for ArrayWrapper. These are compatible with statsample methods.
* Added plotting functions for DataFrame and Vector using Nyaplot.
* Create a DataFrame by specifying the rows with the ".rows" class method.
* Create a Vector from a Hash.
* Call a Vector element by specfying the index name as a method call (method_missing logic).
* Retrive multiple rows of a DataFrame by specfying a Range or an Array with multiple index names.
* #head and #tail for DataFrame.
* #uniq for Vector.
* #max for Vector can return a Vector object with the index set to the index of the max value.
* Tonnes of documentation for most methods.

# 0.0.3.1
* Added aritmetic methods for vector aritmetic by taking the index of values into account.

# 0.0.3
* This release is a complete rewrite of the entire gem to accomodate index values.

# 0.0.2.4
* Initialize dataframe from an array which looks like [{a: 10, b: 20}, {a: 11, b: 12}]. Works for parsed JSON.
* Over-riding vectors in DataFrame will still preserve order.
* Any re-assignment of rows in #each_row and #each_row_with_index will reflect in the DataFrame.
* Added #to_a and #to_json to DataFrame.

# 0.0.2.3
* Added #filter\_rows and #delete_row to DataFrame and changed #row to return a row containing a Hash of column name and value.
* Vector objects passed into a DataFrame are now duplicated so that any changes dont affect the original vector.
* Added an optional opts argument to DataFrame.
* Sending more fields than vectors in DataFrame will cause addition of nil vectors.
* Init a DataFrame without having to convert explicitly to vectors.

# 0.0.2.2
* Added test cases and multiple column access through the [] operator on DataFrames

# 0.0.2.1
* Fixed bugs with previous code and more iterators

# 0.0.2
* Added iterators for dataframe and vector alongwith printing functions (to_html) to interface properly with iRuby notebook.

# 0.0.1
* Added classes for DataFrame and Vector alongwith some super-basic functions to get off the ground
