# daru - Data Analysis in RUby

[![Gem Version](https://badge.fury.io/rb/daru.svg)](http://badge.fury.io/rb/daru)
[![Build Status](https://travis-ci.org/v0dro/daru.svg)](https://travis-ci.org/v0dro/daru)

## Table of Contents



## Introduction

daru (Data Analysis in RUby) is a library for storage, analysis, manipulation and visualization of data in Ruby.

daru makes it easy and intuituive to process data predominantly through 2 data structures: `Daru::DataFrame` and `Daru::Vector`. Written in pure Ruby works with all ruby implementations. Tested with MRI 2.0, 2.1, 2.2 and 2.3.

## Features

* Data structures:
    - Vector - A basic 1-D vector.
    - DataFrame - A 2-D spreadsheet-like structure for manipulating and storing data sets. This is daru's primary data structure.
* Compatible with [IRuby notebook](https://github.com/SciRuby/iruby), [statsample](https://github.com/SciRuby/statsample), [statsample-glm](https://github.com/SciRuby/statsample-glm) and [statsample-timeseries](https://github.com/SciRuby/statsample-timeseries).
* Support for time series.
* Singly and hierarchially indexed data structures.
* Flexible and intuitive API for manipulation and analysis of data.
* Easy plotting, statistics and arithmetic.
* Plentiful iterators.
* Optional speed and space optimization on MRI with [NMatrix](https://github.com/SciRuby/nmatrix) and GSL.
* Easy splitting, aggregation and grouping of data.
* Quickly reducing data with pivot tables for quick data summary.
* Import and export data from and to Excel, CSV, SQL Databases, ActiveRecord and plain text files.

## Basic Usage

daru exposes two major data structures: `DataFrame` and `Vector`. The Vector is a basic 1-D structure corresponding to an Array, while the `DataFrame` - daru's primary data structure - is 2-D spreadsheet-like structure for manipulating and storing data sets.

Basic DataFrame intitialization.

``` ruby
data_frame = Daru::DataFrame.new(
  {
    'Beer' => ['Kingfisher', 'Snow', 'Bud Light', 'Tiger Beer', 'Budweiser'],
    'Gallons sold' => [500, 400, 450, 200, 250]
  }
  index: ['India', 'China', 'USA', 'Malaysia', 'Canada']
)
data_frame
```
![init0](images/init0.png)


Load data from CSV files.
``` ruby
df = Daru::DataFrame.from_csv('TradeoffData.csv')
```
![init1](images/init1.png)

*Basic Data Manipulation*

Selecting columns.
``` ruby
data_frame['Beer']
```
![man0](images/man0.png)

Selecting rows.
``` ruby
data_frame.row['USA']
```
![man1](images/man1.png)

A range of rows.
``` ruby
data_frame.row['India'..'USA']
```
![man2](images/man2.png)

The first 2 rows.
``` ruby
data_frame.first(2)

## Notebooks

#### Notebooks on most use cases

* [Overview of most daru functions](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Daru%20Demo.ipynb)
* [Basic Creation of Vectors and DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Creation%20of%20Vector%20and%20DataFrame.ipynb)
* [Detailed Usage of Daru::Vector](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Usage%20of%20Vector.ipynb)
* [Detailed Usage of Daru::DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Usage%20of%20DataFrame.ipynb)
* [Visualizing Data With Daru::DataFrame](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Visualization/Visualizing%20data%20with%20daru%20DataFrame.ipynb)
* [Searching and combining data in daru](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Searching%20and%20Combining%20Data.ipynb)
* [Grouping, Splitting and Pivoting Data](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Grouping%2C%20Splitting%20and%20Pivoting.ipynb)

#### Notebooks on Time series

* [Basic Time Series](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Basic%20Time%20Series.ipynb)
* [Time Series Analysis and Plotting](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Time%20Series%20Functions.ipynb)

### Case Studies

* [Logistic Regression Analysis with daru and statsample-glm](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Logistic%20Regression%20with%20daru%20and%20statsample-glm.ipynb)
* [Finding and Plotting most heard artists from a Last.fm dataset](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Finding%20and%20plotting%20the%20most%20heard%20artists%20on%20last%20fm.ipynb)
* [Analyzing baby names with daru](http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Analyzing%20baby%20names/Use%20Case%20-%20Daru%20for%20analyzing%20baby%20names%20data.ipynb)

## Blog Posts

* [Data Analysis in RUby: Basic data manipulation and plotting](http://v0dro.github.io/blog/2014/11/25/data-analysis-in-ruby-basic-data-manipulation-and-plotting/)
* [Data Analysis in RUby: Splitting, sorting, aggregating data and data types](http://v0dro.github.io/blog/2015/02/24/data-analysis-in-ruby-part-2/)
* [Finding and Combining data in daru](http://v0dro.github.io/blog/2015/08/03/finding-and-combining-data-in-daru/)

### Time series

* [Analysis of Time Series in daru](http://v0dro.github.io/blog/2015/07/31/analysis-of-time-series-in-daru/)
* [Date Offsets in Daru](http://v0dro.github.io/blog/2015/07/27/date-offsets-in-daru/)

## Documentation

Docs can be found [here](https://rubygems.org/gems/daru).

## Roadmap

* Enable creation of DataFrame by only specifying an NMatrix/MDArray in initialize. Vector naming happens automatically (alphabetic) or is specified in an Array.
* Basic Data manipulation and analysis operations: 
    - DF concat
* Assignment of a column to a single number should set the entire column to that number.
* Multiple column assignment with []=
* Multiple value assignment for vectors with []=.
* #find\_max function which will evaluate a block and return the row for the value of the block is max.
* Sort by index.
* Statistics on DataFrame over rows.
* Calculate percentage change.
* Have some sample data sets for users to play around with. Should be able to load these from the code itself.
* Sorting with missing data present.

## Contributing

Pick a feature from the Roadmap or the issue tracker or think of your own and send me a Pull Request!

For details see [CONTRIBUTING](https://github.com/v0dro/daru/blob/master/CONTRIBUTING.md).

## Acknowledgements

* Google and the Ruby Science Foundation for the Google Summer of Code 2015 grant for further developing daru and integrating it with other ruby gems.
* Thank you [last.fm](http://www.last.fm/) for making user data accessible to the public.

Copyright (c) 2015, Sameer Deshmukh
All rights reserved
