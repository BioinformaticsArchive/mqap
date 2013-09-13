#!/bin/csh -f

set SRC = ~/Bio/Code/perl_scripts
if($#argv != 3  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set dirscores = $PWD/SCORES.ALL/

set runfile = $PWD/run.csh



set distdiff = $dir/dist.diff
set potdiff = $dir/pot.diff

\rm -f $distdiff
\rm -f $potdiff

touch $distdiff
touch $potdiff 

cd $dir
foreach query ( ` cat $listquery` )
    if(-e $query/dis.diff && -e $query/pot.diff) then 
	echo  $query >> $distdiff 
	cat  $query/dis.diff >> $distdiff
	echo  $query >> $potdiff 
	cat  $query/pot.diff >> $potdiff
	endif 
end 
cd -




cd $PWD
