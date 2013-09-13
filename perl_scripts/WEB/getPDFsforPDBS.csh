#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set list = $PWD/$1

automateGetPDB.pl -out out.csh -in $list
source out.csh

foreach i ( ` cat $list` )
	getPDF.pl -out $i.csh -pdb $i -in $i.html
	source  $i.csh
end


