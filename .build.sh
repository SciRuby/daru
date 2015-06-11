#!/bin/bash

git clone https://github.com/SciRuby/nmatrix.git
cd nmatrix
gem build nmatrix.gemspec
gem install nmatrix-0.1.0.gem
cd ..
rm -rf nmatrix
git clone https://github.com/v0dro/gsl-nmatrix
cd gsl-nmatrix
gem build gsl-nmatrix.gemspec
gem install gsl-nmatrix-1.17.gem
cd ..
rm -rf gsl-nmatrix