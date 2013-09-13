#!/bin/csh -f

if($#argv != 1  ) then 
   #echo "Wrong numnber of args"
  #exit 
endif 



set dir = $1


cd $dir

foreach i ( ` cat list.diff `)
  echo removing $i
  \rm $i 
end 
exit 


