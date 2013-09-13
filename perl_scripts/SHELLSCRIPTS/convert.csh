#!/bin/csh -fv

if($#argv != 3  ) then 
  echo "Usage : "
  exit 
endif 

convert $1 -resize $3% $2


