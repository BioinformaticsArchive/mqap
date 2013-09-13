#!/bin/csh -f

if($#argv != 1  ) then 
   #echo "Wrong numnber of args"
  #exit 
endif 



set dir = $1

cd $dir

foreach i ( ` cat $dir/list.diff `)
  echo diffing $i
  pwd
  echo diff $dir/GOLD/$i $dir/$i
  diff -w $dir/GOLD/$i $dir/$i > $dir/diff.log
end 


cd - 
