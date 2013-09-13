#!/bin/csh -f

if($#argv != 1  ) then 
   echo "Wrong numnber of args"
  exit 
endif 



$PWD = ` pwd ` 
set dir = $PWD/$1


$SRC/REGR/pre.csh $dir
cd $dir 
echo Running $dir/do.csh 
$dir/do.csh 
cd -

$SRC/REGR/post.csh $dir

