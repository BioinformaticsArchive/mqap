#!/bin/csh -f

if($#argv != 2  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listquery = $1
set dir = $2



#$SRC/CSA/generateScores.csh list.all $listquery $dir 
$SRC/CSA/generateScores.csh list.CSA.3 $listquery $dir 
$SRC/CSA/generateScores.csh list.CSA.4  $listquery $dir
$SRC/CSA/generateScores.csh list.CSA.5  $listquery $dir
$SRC/CSA/generateScores.csh list.CSA.6  $listquery $dir

