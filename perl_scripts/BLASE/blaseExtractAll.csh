#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set out=scores.$1 
set needledir=$2
newfile.csh $out 

blaseExtractNeedleScores.csh $1 A $out $needledir 
#blaseExtractNeedleScores.csh $1 C $out $needledir 
#blaseExtractNeedleScores.csh $1 D $out $needledir 
blaseExtractNeedleScores.csh $1 PBP $out $needledir 
#blaseExtractNeedleScores.csh $1 ST $out $needledir 
