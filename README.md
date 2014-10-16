daru
====

Data Analysis in RUby

[![Gem Version](https://badge.fury.io/rb/daru.svg)](http://badge.fury.io/rb/daru)

## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis and manipulation of data. It aims to be the preferred data analysis library for Ruby. 

Development of daru was started to address the fragmentation of Dataframe-like classes which were created in many ruby gems as per their own needs. 

This creates a hurdle in using these gems together to solve a problem. For example, calculating something in [statsample](https://github.com/clbustos/statsample) and plotting the results in [Nyaplot](https://github.com/domitry/nyaplot).

daru is heavily inspired by `Statsample::Dataset`, `Nyaplot::DataFrame` and the super-awesome pandas, a very mature solution in Python.

## Data Structures

daru employs several data structures for storing and manipulating data:
* Vector - A basic 1-D vector.
* DataFrame - A 2-D matrix-like structure which is internally composed of named `Vector` classes.

daru data structures can be constructed by using several Ruby classes. These include `Array`, `Hash`, `Matrix`, [NMatrix](https://github.com/SciRuby/nmatrix) and [MDArray](https://github.com/rbotafogo/mdarray). daru brings a uniform API for handling and manipulating data represented in any of the above Ruby classes.

## Testing

Install jruby using `rvm install jruby`, then run `jruby -S gem install mdarray`, followed by `bundle install`. You will need to install `mdarray` manually because of strange gemspec file behaviour. If anyone can automate this then I'd greatly appreciate it! Then run `rspec` in JRuby to test for MDArray functionality.

Then switch to MRI, do a normal `bundle install` followed by `rspec` for testing everything else with NMatrix functionality.

## Roadmap

* Automate testing for both MRI and JRuby.
* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Add support for missing values in vectors.
* Destructive version #filter\_rows!
* NMatrix.first should return NMatrix (in vector).
* Completely test all functionality for NMatrix and MDArray.
* Basic Data manipulation and analysis operations: 
    - Different kinds of join operations
    - Dataframe/vector merge
    - Creation of correlation, covariance matrices
    - Verification of data in a vector
    - Basic vector statistics - mean, median, variance, etc.
* Add indexing on vectors.
    - Creation of vector by supplying an index-value hash.
    - Auto generation of real numbered indices for any vector.
    - Ability to separately specify index for each element of a vector.
    - Runtime alteration of index.
* Indexing on DataFrame.
* Vector arithmetic - elementwise addition, subtraction, multiplication, division.
* Transpose a dataframe.
* Option to express a DataFrame as an NMatrix or MDArray so as to use more efficient storage techniques.
* Pretty printing for the command line.
* Assignment of a column to a single number should set the entire column to that number.
* == between daru_vector and string/number.
* Multiple column assignment with []=
* Creation of DataFrame from Array of Arrays.