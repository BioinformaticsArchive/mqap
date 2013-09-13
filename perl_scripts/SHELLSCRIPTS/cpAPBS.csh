#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set pdb  = $1
set dir = $2

cp -r $pdb $dir
echo $pdb >> $dir/list 

