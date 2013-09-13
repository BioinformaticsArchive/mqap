#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set i = $1 
set newname=`echo $i | tr "[:lower:]" "[:upper:]"`
echo $newname 

vi $PDBDIR/$newname.pdb
