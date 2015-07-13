daru
====

Data Analysis in RUby

[![Gem Version](https://badge.fury.io/rb/daru.svg)](http://badge.fury.io/rb/daru)
[![Build Status](https://travis-ci.org/v0dro/daru.svg)](https://travis-ci.org/v0dro/daru)

## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis, manipulation and visualization of data.

daru is inspired by pandas, a very mature solution in Python.

Written in pure Ruby so should work with all ruby implementations. Tested with MRI 2.0, 2.1, 2.2.

## Features

* Data structures:
    - Vector - A basic 1-D vector.
    - DataFrame - A 2-D spreadsheet-like structure for manipulating and storing data sets. This is daru's primary data structure.
* Compatible with [IRuby notebook](https://github.com/SciRuby/iruby), [statsample](https://github.com/SciRuby/statsample) and [statsample-glm]().
* Singly and hierarchially indexed data structures.
* Flexible and intuitive API for manipulation and analysis of data.
* Easy plotting, statistics and arithmetic.
* Plentiful iterators.
* Optional speed and space optimization on MRI with [NMatrix](https://github.com/SciRuby/nmatrix) and GSL.
* Easy splitting, aggregation and grouping of data.
* Quickly reducing data with pivot tables for quick data summary.
* Import and exports dataset from and to Excel, CSV, Databases and plain text files.

## Notebooks

### Usage

* [Basic Creation of Vectors and DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Creation%20of%20Vector%20and%20DataFrame.ipynb)
* [Detailed Usage of Daru::Vector](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Usage%20of%20Vector.ipynb)
* [Detailed Usage of Daru::DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Usage%20of%20DataFrame.ipynb)
* [Visualizing Data With Daru::DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Visualization/Visualizing%20data%20with%20daru%20DataFrame.ipynb)
* [Grouping, Splitting and Pivoting Data](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Grouping%2C%20Splitting%20and%20Pivoting.ipynb)

### Case Studies

* [Logistic Regression Analysis with daru and statsample-glm](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Logistic%20Regression%20with%20daru%20and%20statsample-glm.ipynb)
* [Finding and Plotting most heard artists from a Last.fm dataset](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Finding%20and%20plotting%20the%20most%20heard%20artists%20on%20last%20fm.ipynb)

## Blog Posts

* [Data Analysis in RUby: Basic data manipulation and plotting](http://v0dro.github.io/blog/2014/11/25/data-analysis-in-ruby-basic-data-manipulation-and-plotting/)
* [Data Analysis in RUby: Splitting, sorting, aggregating data and data types](http://v0dro.github.io/blog/2015/02/24/data-analysis-in-ruby-part-2/)

## Documentation

Docs can be found [here](https://rubygems.org/gems/daru).

## Roadmap

* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Basic Data manipulation and analysis operations: 
    - DF concat
* Assignment of a column to a single number should set the entire column to that number.
* == between daru_vector and string/number.
* Multiple column assignment with []=
* Multiple value assignment for vectors with []=.
* #find\_max function which will evaluate a block and return the row for the value of the block is max.
* Function to check if a value of a row/vector is within a specified range.
* Create a new vector in map_rows if any of the already present rows dont match the one assigned in the block.
* Sort by index.
* Statistics on DataFrame over rows and columns.
* Cumulative sum.
* Calculate percentage change.
* Have some sample data sets for users to play around with. Should be able to load these from the code itself.
* Sorting with missing data present.
* Change internals of indexes to raise errors when a particular index is missing and the passed key is a Fixnum. Right now we just return the Fixnum for convienience.

## Contributing

Pick a feature from the Roadmap or the issue tracker or think of your own and send me a Pull Request!

## Acknowledgements

* Google and the Ruby Science Foundation for the Google Summer of Code 2015 grant for further developing daru and integrating it with other ruby gems.
* Thank you [last.fm](http://www.last.fm/) for making user data accessible to the public.

Copyright (c) 2015, Sameer Deshmukh
All rights reserved
