daru
====

Data Analysis in RUby

[![Gem Version](https://badge.fury.io/rb/daru.svg)](http://badge.fury.io/rb/daru)

## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis and manipulation of data.

Development of daru was started to address the fragmentation of Dataframe-like classes which were created in many ruby gems as per their own needs. daru offers a uniform interface for all sorts of data analysis and manipulation operations and aims to be compatible with all ruby gems involved in any way with data.

daru is heavily inspired by `Statsample::Dataset`, `Nyaplot::DataFrame` and the super-awesome pandas, a very mature solution in Python.

daru works with CRuby (1.9.3+) and JRuby and in a few weeks will be completely compatible with NMatrix and MDArray for fast data manipulation using C or Java structures.

## Features

* Data structures:
    - Vector - A basic 1-D vector.
    - DataFrame - A 2-D matrix-like structure which is internally composed of named `Vector` classes.
* Compatible with IRuby notebook.
* Indexed and named data structures.
* Flexible and intuitive API for manipulation and analysis of data.

## Usage

daru has been created with keeping extreme ease of use in mind.

The gem consists of two data structures, Vector and DataFrame. Any data in a serial format is a Vector and a table is a DataFrame.

#### Initialization of DataFrame

A data frame can be initialized from the following sources:
* Hash of indexed vectors: `{ b: Daru::Vector.new(:b, [11,12,13,14,15], [:two, :one, :four, :five, :three]), a: Daru::Vector.new(:a, [1,2,3,4,5], [:two,:one,:three, :four, :five])}`.
* Array of hashes: `[{a: 1, b: 11}, {a: 2, b: 12}, {a: 3, b: 13},{a: 4, b: 14}, {a: 5, b: 15}]`.
* Hash of names and Arrays: `{b: [11,12,13,14,15], a: [1,2,3,4,5]}`

The DataFrame constructor takes 4 arguments: source, vectors, indexes and name in that order. The last 3 are optional while the first is mandatory.

A basic DataFrame can be initialized like this:

```ruby

    df = Daru::DataFrame.new({b: [11,12,13,14,15], a: [1,2,3,4,5]}, [:a, :b],
        [:one, :two, :three, :four, :five])
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
        [:a, :b]
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
      }, [:a, :b, :c, :d], [:one, :two, :three, :four, :five, :six])
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
           [:a, :b]
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

    dv = Daru::Vector.new :ravan, [1,2,3,4,5], [:ek, :don, :teen, :char, :pach]
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

    dv = Daru::Vector.new :yoga, [1,2,3], [0,1,2,3,4]
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
        [:a, :b]
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

    df.keep_row_if do |row|
        row[:a] == 5
    end

    df
    #  => 
    # #<Daru::DataFrame:87455010 @name = b3d14e23-98c2-4741-a563-92e8f1fd0f13 # @size = 1>
    #         a    b 
    # five    5   14 

```
The same can be applied to vectors using `keep_vector_if`.

To iterate over a DataFrame and perform operations on rows or vectors, `#each_row` or `#each_vector` can be used, which works just like `#each` for Ruby Arrays.

To change the values of a row/vector while iterating through the DataFrame, use `map_rows` or `map_vectors`:

```ruby

    df.map_rows do |row|
        row = row.map { |e| e*e }
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

#### Basic Math Operations

Coming soon!

## Roadmap

* Automate testing for both MRI and JRuby.
* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Destructive map iterators for DataFrame and Vector.
* Completely test all functionality for NMatrix and MDArray.
* Basic Data manipulation and analysis operations: 
    - Different kinds of join operations
    - Dataframe/vector merge
    - Creation of correlation, covariance matrices
    - Verification of data in a vector
    - Basic vector statistics - mean, median, variance, etc.
* Vector arithmetic - elementwise addition, subtraction, multiplication, division.
* Transpose a dataframe.
* Option to express a DataFrame as an NMatrix or MDArray so as to use more efficient storage techniques.
* Assignment of a column to a single number should set the entire column to that number.
* == between daru_vector and string/number.
* Multiple column assignment with []=
* Creation of DataFrame from Array of Arrays.
* Multiple value assignment for vectors with []=.
* Load DataFrame from multiple sources (excel, SQL, etc.).
* Allow for boolean operations inside #[].
* Deletion of elements from Vector should only modify the index and leave the vector as it is so that compacting is not needed and things are faster.
* Add a #sync method which will sync the modified index with the unmodified vector.
* Ability to reorder the index of a dataframe.
* Slicing operations using Range.
* Create DataFrame by providing rows.
* Integrate basic plotting with Nyaplot.
* Filter through a dataframe with filter\_rows or filter\_vectors based on whatever boolean value evaluates to true.
* Named arguments

Copyright (c) 2014, Sameer Deshmukh
All rights reserved
