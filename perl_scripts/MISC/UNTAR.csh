#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 


echo untarring $1, log in $1.log

tar -xvzf $1 > & ! $1.log & 
