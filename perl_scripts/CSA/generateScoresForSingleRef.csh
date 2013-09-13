#!/bin/csh -f

if($#argv != 5  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set ref = $1
set dir = $PWD/$2
set dirscores = $dir/$3
set listref = $PWD/$4
set listquery = $PWD/$5

set finalfile = $dirscores/$ref.single.sorted.annotated
if(-e $finalfile) then 
   echo "$finalfile already exists"
   exit 0 
endif

set refdirscores = $dir//SCORES.$ref/


$SRC/SHELLSCRIPTS/makeDirScores.csh $dirscores

mkdir -p $dir//SCORES.$ref/ 	 
\rm -f $dir//SCORES.$ref/*
cd $dir//SCORES.$ref 	 
ln -s ../ANNOTATE .
foreach query ( ` cat $listquery` )
	if(-e ../$query/$query.$ref.pdb.out) then 
     ln -s ../$query/$query.$ref.pdb.out .
	endif 
end 
$SRC/MISC/checkAllSizesAreSameInAllOutFiles.pl 
if($status != 0) then 
	echo $SRC/MISC/checkAllSizesAreSameInAllOutFiles.pl failed
	exit 1 
endif 

touch /tmp/list.junk
$SRC/SHELLSCRIPTS/getFreqSingle.csh $ref /tmp/list.junk  /tmp/list.junk 
\cp -f $ref.sorted.annotated $finalfile
echo Final file is in $finalfile


#$SRC/CSA/createPdfs.csh list.$1 list $2


cd $PWD
