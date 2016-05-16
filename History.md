# 0.1.3.1 (12 May 2016)

* Fixes
    - Fixed small error with usage of newly introduced #each_with_object.

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
