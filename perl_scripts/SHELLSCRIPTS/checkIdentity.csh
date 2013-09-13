#!/bin/csh -fv

if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set listref = $1
set listquery = $2
set out = $3
set arg = $4

\rm -f KKKK
touch KKKK 
echo $1 >> KKKK
echo $2 >> KKKK

set tmpfile=`getTmpFileName.pl`

checkIdentity.pl -out ooo -list KKKK -simi 60 -save -arg $arg -needle $tmpfile
mv -f $tmpfile $out



