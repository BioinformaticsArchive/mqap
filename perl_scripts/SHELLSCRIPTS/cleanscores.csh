#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set dir = $1 

\rm -rf $dir/SCORES* 
\rm -rf $dir/*/SCORES*

