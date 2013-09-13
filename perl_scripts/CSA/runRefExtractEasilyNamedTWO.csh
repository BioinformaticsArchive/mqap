#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = list.$1
set listquery = list.$2

$SRC/SHELLSCRIPTS/newfile.csh $listref
$SRC/SHELLSCRIPTS/newfile.csh $listquery

echo $1 >> $listref 
echo $2 >> $listquery 

$SRC/CSA/runRefExtractEasilyNamed.csh  $listref $listquery

