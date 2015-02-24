daru
====

Data Analysis in RUby

[![Gem Version](https://badge.fury.io/rb/daru.svg)](http://badge.fury.io/rb/daru)

## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis and manipulation of data.

daru is inspired by `Statsample::Dataset` and pandas, a very mature solution in Python.

Written in pure Ruby so should work with all ruby implementations.

## Features

* Data structures:
    - Vector - A basic 1-D vector.
    - DataFrame - A 2-D matrix-like structure which is internally composed of named `Vectors`.
* Compatible with [IRuby notebook](https://github.com/minad/iruby) and [statsample](https://github.com/clbustos/statsample).
* Singly and hierarchially indexed data structures.
* Flexible and intuitive API for manipulation and analysis of data.
* Easy plotting, statistics and arithmetic.
* Plentiful iterators.
* Optional speed and space optimization on MRI with [NMatrix](https://github.com/SciRuby/nmatrix).
* Easy splitting, aggregation and grouping of data.
* Quickly reducing data with pivot tables for quick data summary.

## Notebooks

* [Analysis and plotting of a data set comprising of music listening habits of a last.fm user(iruby notebook)](http://nbviewer.ipython.org/github/v0dro/daru/blob/master/notebooks/intro_with_music_data_.ipynb)

## Blog Posts

* [Data Analysis in RUby: Basic data manipulation and plotting](http://v0dro.github.io/blog/2014/11/25/data-analysis-in-ruby-basic-data-manipulation-and-plotting/)

## Documentation

Docs can be found [here](https://rubygems.org/gems/daru).

## Overview

Coming soon.

## Basic Usage

#### Initialization of DataFrame

A basic DataFrame can be initialized like this:

```ruby

    df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, order: [:a, :b], index: [:one, :two, :three, :four, :five])
    df
    # => 
    # # <Daru::DataFrame:87274040 @name = 7308c587-4073-4e7d-b3ca-3679d1dcc946 # @size = 5>
    #           a     b 
    #   one     1    11 
    #   two     2    12 
    # three     3    13 
    #  four     4    14 
    #  five     5    15 

```
Daru will automatically align the vectors correctly according to the specified index and then create the DataFrame. Thus, elements having the same index will show up in the same row. The indexes will be arranged alphabetically if vectors with unaligned indexes are supplied.

The vectors of the DataFrame will be arranged according to the array specified in the (optional) second argument. Otherwise the vectors are ordered alphabetically.

```ruby

    df = Daru::DataFrame.new({
        b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]), 
        a:      [1,2,3,4,5].dv(:a, [:two,:one,:three, :four, :five])
      }, 
        order: [:a, :b]
      )
    df

    # => 
    # #<Daru::DataFrame:87363700 @name = 75ba0a14-8291-48ac-ac30-35017e4d6c5f # @size = 5>
    #           a     b 
    #  five     5    14 
    #  four     4    13 
    #   one     2    12 
    # three     3    15 
    #   two     1    11

```

If an index for the DataFrame is supplied (third argument), then the indexes of the individual vectors will be matched to the DataFrame index. If any of the indexes do not match, nils will be inserted instead:

```ruby

    df = Daru::DataFrame.new({
        b: [11]                .dv(nil, [:one]), 
        a: [1,2,3]             .dv(nil, [:one, :two, :three]), 
        c: [11,22,33,44,55]    .dv(nil, [:one, :two, :three, :four, :five]),
        d: [49,69,89,99,108,44].dv(nil, [:one, :two, :three, :four, :five, :six])
      }, order: [:a, :b, :c, :d], index: [:one, :two, :three, :four, :five, :six])
    df
    # => 
    # #<Daru::DataFrame:87523270 @name = bda4eb68-afdd-4404-9981-708edab14201  #@size = 6>
    #           a     b     c     d 
    #   one     1    11    11    49 
    #   two     2   nil    22    69 
    # three     3   nil    33    89 
    #  four   nil   nil    44    99 
    #  five   nil   nil    55   108 
    #   six   nil   nil   nil    44 

```

If some of the supplied vectors do not contain certain indexes that are contained in other vectors, they are added to those vectors and the correspoding elements are set to `nil`.

```ruby

    df = Daru::DataFrame.new({
             b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]), 
             a: [1,2,3]         .dv(:a, [:two,:one,:three])
           }, 
           order: [:a, :b]
         )
    df

    #  => 
    # #<Daru::DataFrame:87612510 @name = 1e904c15-e095-4dce-bfdf-c07ee4d6e4a4 # @size = 5>
    #           a     b 
    #  five   nil    14 
    #  four   nil    13 
    #   one     2    12 
    # three     3    15 
    #   two     1    11 

```

#### Initialization of Vector

The `Vector` data structure is also named and indexed. It accepts arguments name, source, index (in that order).

In the simplest case it can be constructed like this:

```ruby

    dv = Daru::Vector.new [1,2,3,4,5], name: ravan, index: [:ek, :don, :teen, :char, :pach]
    dv

    #  => 
    # #<Daru::Vector:87630270 @name = ravan @size = 5 >
    #     ravan
    #   ek    1
    #  don    2
    # teen    3
    # char    4
    # pach    5 

```

Initializing a vector with indexes will insert nils in places where elements dont exist:

```ruby

    dv = Daru::Vector.new [1,2,3], name: yoga, index: [0,1,2,3,4]
    dv
    #  => 
    # #<Daru::Vector:87890840 @name = yoga @size = 5 >
    #   y
    # 0 1
    # 1 2
    # 2 3
    # 3 nil 
    # 4 nil 


```

#### Basic Selection Operations

Initialize a dataframe:

```ruby

    df = Daru::DataFrame.new({
        b: [11,12,13,14,15].dv(:b, [:two, :one, :four, :five, :three]), 
        a:      [1,2,3,4,5].dv(:a, [:two,:one,:three, :four, :five])
      }, 
        order: [:a, :b]
      )

    #  => 
    # #<Daru::DataFrame:87455010 @name = b3d14e23-98c2-4741-a563-92e8f1fd0f13 # @size = 5>
    #           a     b 
    #  five     5    14 
    #  four     4    13 
    #   one     2    12 
    # three     3    15 
    #   two     1    11 

```
Select a row from a DataFrame:

```ruby
    
    df.row[:one]

    #  => 
    # #<Daru::Vector:87432070 @name = one @size = 2 >
    #    one
    #  a  2
    #  b 12 
```
A row or a vector is returned as a `Daru::Vector` object, so any manipulations supported by `Daru::Vector` can be performed on the chosen row as well.

Select multiple rows with a Range and get a DataFrame in return:

``` ruby

df.row[1..3] # OR df.row[:four..:three]
# => 
#<Daru::DataFrame:85361520 @name = d6582f66-5a55-473e-ba57-cb2ba974da6a @size #= 3>
#                    a          b 
#      four          4         13 
#       one          2         12 
#     three          3         15 

```

Select a single vector:

```ruby
    
    df.vector[:a] # or simply df.a

    #  => 
    # #<Daru::Vector:87454270 @name = a @size = 5 >
    #           a
    #  five     5
    #  four     4
    #   one     2
    # three     3
    #   two     1

```

Select multiple vectors and return a DataFrame in the specified order:

```ruby

    df.vector[:b, :a]
    #  =>
    # #<Daru::DataFrame:87835960 @name = e80902cc-cff9-4b23-9eca-5da36ebc88a8 #   @size = 5>
    #           b     a 
    #  five    14     5 
    #  four    13     4 
    #   one    12     2 
    # three    15     3 
    #   two    11     1 

```

Keep/remove row according to a specified condition:

```ruby

    df = df.filter_rows do |row|
        row[:a] == 5
    end

    df
    #  => 
    # #<Daru::DataFrame:87455010 @name = b3d14e23-98c2-4741-a563-92e8f1fd0f13 # @size = 1>
    #         a    b 
    # five    5   14 

```
The same can be applied to vectors using `filter_vectors`.

To iterate over a DataFrame and perform operations on rows or vectors, use `#each_row` or `#each_vector`.

To change the values of a row/vector while iterating through the DataFrame, use `map_rows` or `map_vectors`:

```ruby

    df.map_rows do |row|
        row = row * row
    end

    df

    #  => 
    # #<Daru::DataFrame:86826830 @name = b092ca5b-7b83-4dbe-a469-124f7f25a568 # @size = 5>
    #           a     b 
    #  five    25   196 
    #  four    16   169 
    #   one     4   144 
    # three     9   225 
    #   two     1   121 

```

Rows/vectors can be deleted using `delete_row` or `delete_vector`.

#### Basic Maths Operations

Performing a binary arithmetic operation on two `Daru::Vector` objects will return a `Vector` object in which the operation will be performed on elements of the same index.

```ruby

    dv1 = Daru::Vector.new [1,2,3,4], name: :boozy, index: [:a, :b, :c, :d]

    dv2 = Daru::Vector.new [1,2,3,4], name: :mayer, index: [:e, :f, :b, :d]

    dv1 * dv2

    # #<Daru::Vector:80924700 @name = boozy @size = 2 >
    #         boozy
    #      b      6
    #      d     16
 
```

Arithmetic operators applied on a single Numeric will perform the operation with that number against the entire vector.

#### Statistics Operations

Daru::Vector has a whole lot of statistics operations to maintain compatibility with Statsample::Vector. Check the docs for details.

#### Plotting

daru uses [Nyaplot](https://github.com/domitry/nyaplot) for plotting and an example of this can be found in the [notebook](http://nbviewer.ipython.org/github/v0dro/daru/blob/master/notebooks/intro_with_music_data_.ipynb) or [blog post](http://v0dro.github.io/blog/2014/11/25/data-analysis-in-ruby-basic-data-manipulation-and-plotting/).

Head over to the tutorials and notebooks listed above for more examples.

## Roadmap

* Automate testing for both MRI and JRuby.
* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Destructive map iterators for DataFrame.
* Completely test all functionality for MDArray.
* Basic Data manipulation and analysis operations: 
    - Different kinds of join operations
    - Dataframe/vector merge (left, right, inner, outer)
    - Verification of data in a vector
    - DF concat
* Option to express a DataFrame as an NMatrix or MDArray so as to use more efficient storage techniques.
* Assignment of a column to a single number should set the entire column to that number.
* == between daru_vector and string/number.
* Multiple column assignment with []=
* Multiple value assignment for vectors with []=.
* Load DataFrame from multiple sources (excel, SQL, etc.).
* Deletion of elements from Vector should only modify the index and leave the vector as it is so that compacting is not needed and things are faster.
* #find\_max function which will evaluate a block and return the row for the value of the block is max.
* Function to check if a value of a row/vector is within a specified range.
* Create a new vector in map_rows if any of the already present rows dont match the one assigned in the block.
* Sort by index.
* Statistics on DataFrame over rows and columns.
* Produce multiple summary statistics in one shot.
* Cumulative sum.
* Time series support.
* Calculate percentage change.
* Working with missing data - drop\_missing\_data, dropping rows with missing data.
* Have some sample data sets for users to play around with. Should be able to load these from the code itself.
* Sorting with missing data present.
* Make vectors aware of the data frame that they are a part of.
* re_index should re establish previous index values in the newly supplied index.
* Reset index.

## Contributing

Pick a feature from the Roadmap above or think of your own and send me a Pull Request!

## Acknowledgements

* Thank you [last.fm](http://www.last.fm/) for making user data accessible to the public.

Copyright (c) 2015, Sameer Deshmukh
All rights reserved
