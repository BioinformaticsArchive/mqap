#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 


\rm -f $1
touch $1
echo "Writing $PWD/$1"

