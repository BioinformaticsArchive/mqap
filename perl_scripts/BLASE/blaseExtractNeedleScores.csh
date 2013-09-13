#!/bin/csh -f

if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set REF=$1 
set what=$2 
set out=$3 
set needledir=$4

set ref=` cat motif.$REF `


touch $out 

set list=list.$what

echo ============= $what ======================= >> $out 
foreach i ( ` cat $list ` )
	if(-e $needledir/$ref.$i.needle.out ) then 
        echo $i  >> $out 
        cat $needledir/$ref.$i.needle.out | egrep -i  "Score|Gaps|Identity|Similar" >> $out 
	endif 
end 



