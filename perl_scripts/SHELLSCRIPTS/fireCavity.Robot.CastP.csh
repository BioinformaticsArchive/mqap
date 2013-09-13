#!/bin/csh 
if($#argv != 2  ) then 
  echo "Usage : EXEC   <list> <htmlfile> "
  exit 
endif 

set list=$1
set htmlfile=$2

lc.pl -in $list -out oooooooooooo -same
foreach i ( ` cat $list ` )
   echo $i 
   ~/oper_scripts/scripts/replacestring.pl -with_what $i -which TTTT -in $htmlfile  -out $i.html
   firefox $i.html & 
  sleep 15 
end 


