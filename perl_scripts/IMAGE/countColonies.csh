#!/bin/csh -f

if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set dir = $PWD/$2
set csv = $PWD/out.csv
set thresh = $3
set color = $4


mkdir -p $dir
\rm -rf $csv
touch $csv
echo " Name, blue , red, others , blue , red, others , blue , red, others , blue , red, others , blue , red, others , blue , red, others ,  " >> $csv 

foreach ref ( ` cat $listref` )
  echo PROCESSING $ref 
  mkdir -p $dir/$ref.dir 	
  cd $dir/$ref.dir 	
  #if(! -e $ref.csv) then 
       cp -r  $PWD/$ref . 
       $SRC/IMAGE/countColonies.pl -out results.$ref -in $ref -color $color -csv $ref.csv  -thresh $thresh
  #endif 
  cat $ref.csv >> $csv
  cd $PWD 
end

