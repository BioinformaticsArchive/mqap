#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

if (! -e A) then 
   echo "Need Directories A and B"
   exit 
endif 
if (! -e list) then 
   echo "Need list file "
   exit 
endif 

set PWD = ` pwd`
set listref = $PWD/A/$1
set csv = $PWD/out.csv



\cp -f list A/
cd A 
newfile.csh ../list.ann
foreach ref ( ` cat $listref` )
  echo PRE PROCESSING $ref 
  $SRC/IMAGE/getCircleContour.pl -out out.contour.png -in $ref -color blue -color red -csv $ref.csv  -annotate ../list.ann
end
cd ..

