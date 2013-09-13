#!/bin/csh -f
if($#argv != 3) then 
  echo "Usage : "
  exit 
endif 

set list = $1
set dist = $2
set anndir = $3


createClosetoAnnotate.pl -list $list -dist $dist -ann $anndir

#mkdir -p $i.outfiles
#\rm -f $i.outfiles/* 
#cp $i*fasta $i*ann* $i.outfiles

#\rm HHH 


