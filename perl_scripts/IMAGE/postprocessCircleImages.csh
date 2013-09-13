#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

if (! -e "B") then
   echo "Need Directories A and B"
   exit
endif

if (! -e list) then
   echo "Need list file "
   exit 
endif 

set PWD = ` pwd`
set listref = $PWD/B/$1
set dir = $PWD/B/$2
set csv = $PWD/B/out.csv
set annfile = $PWD/list.ann


mkdir -p $dir
\rm -rf $csv
touch $csv
echo " Name, blue , red, others , blue , red, others , blue , red, others , blue , red, others , blue , red, others , blue , red, others ,  " >> $csv 


\cp -f list B/
foreach ref ( ` cat $listref` )
  cd B 
  echo POST PROCESSING $ref 
  mkdir -p $dir/$ref.dir 	
  cd $dir/$ref.dir 	
  if(! -e $ref.csv) then 
       cp -r  $PWD/B/$ref . 
       $SRC/IMAGE/changeColor.pl -in $ref -from red -to white
       $SRC/IMAGE/changeColor.pl -in $ref -from blue -to white
       $SRC/IMAGE/changeColor.pl -in $ref -from black -to white
       $SRC/IMAGE/getCircleContour.pl -out out.contour.png -in $ref -color blue -color red -csv $ref.csv  -list $annfile
  endif 
  cat $ref.csv >> $csv
  cd $PWD 
end


