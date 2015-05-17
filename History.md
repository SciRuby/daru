# 0.0.6

* Fixes
    - Update documentation and fix it in other places.
    - Fix Vector#sum_of_squares and #ranked.
    - Fixed some tests that were giving RSpec warnings
* Enhancements
    - Wrote a proper .travis.yml
    - Added optional GSL dependency gsl-nmatrix
    - Added Marshalling and unMarshalling capabilities to Vector, Index and 
    DataFrame.
    - Added new methods Daru::IO.save and Daru::IO.load for saving and loading data to and from files by marshalling.
    - Vector
        - #center
        - #standardize
        - #vector_percentile
        - Added a new wrapper class Daru::Accessors::GSLWrapper for wrapping around GSL::Vector, which works similarly to NMatrixWrapper or ArrayWrapper.
        - Added a host of statistical methods to GSLWrapper in Daru::Accessors::GSLStatistics that call the relevant GSL::Vector functions for super-fast C level computations.
        - More stats functions - #vector_standarized_compute, #vector_centered_compute, #sample_with_replacement, #sample_without_replacement
        - #only_valid for creating a Vector with only non-nil data
        - Ported many Statsample::Vector stat methods to Daru::Vector. These are: #percentile, #factors, etc.
        - Added .new_with_size for creating vectors by specifying a size for the
        vector and a block for generating values.
        - Added Vector#verify, #recode! and #recode.
        - Added #save, #jackknife and #bootstrap.
    - DataFrame
        - #dup_only_valid
        - #clone
        - #[]= does not clone the vector if it has the same index as the DataFrame.
        - Added a :clone option to initialize that will not clone Daru::Vectors passed into the constructor.
        - Added #save.
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
