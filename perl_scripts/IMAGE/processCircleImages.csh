#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 


$SRC/IMAGE/preprocessCircleImages.csh $1 $2
$SRC/IMAGE/postprocessCircleImages.csh $1 $2

