#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : "
  exit 
endif 

set thresh = $3 
set size = $4 
set arg = $5 

fragmentcompare.pl -outfile kkk -in1 $1 -in2 $2 -thresh $thresh -size $size -arg $arg
if(! -e "done" ) then 
   source kkk
endif 


$SRC/FRAGALWEB/runAllAndWeb.csh $1 $2 $thresh $size $arg 
