#!/bin/csh -f

if($#argv != 6  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set tag = $4
set promfile = $5
set dist = $6
set dirscores = $dir/SCORES.ALL/

$SRC/SHELLSCRIPTS/makeDirScores.csh $dirscores
cp -rf ANNOTATE/ $dirscores




foreach query ( ` cat $listquery` )
       set finalfile = $dirscores/$query.$tag.sorted.annotated
	   if(-e $finalfile) then 
	   	   echo "file $finalfile already exists"
	       continue 
	   endif 

	   echo "Running generateScores.csh for $query in $dir/$query/SCORES/"
       mkdir -p $dir/$query/SCORES/ 	 
       cd $dir/$query/SCORES 	 

	   \rm *

	   ln -s  ../../ANNOTATE/ .

       foreach ref ( ` cat $listref` )
	       if(  -e ../$query.$ref.pdb.out &&  ! -z ../$query.$ref.pdb.out ) then 
	           ln -s ../$query.$ref.pdb.out .
			   cp -f ../$query.$ref.pdb.out $dirscores/$query.$ref.pdb.out.txt
			   cp -f ../$query.$ref.potential.diff* $dirscores/
			   cp -f ../$query.$ref.distance.diff* $dirscores/ 
		   endif 
	   end

	   echo running $SRC/SHELLSCRIPTS/getFreq.csh $query $listref $listref
	   $SRC/SHELLSCRIPTS/getFreq.csh $query $listref $listref $promfile $dist

	   cp -f $query.sorted $dirscores/$query.$tag.sorted
	   cp -f $query.sorted.annotated $finalfile

	   echo "done generateScores.csh - wrote final file in  $finalfile"
	   echo 
       cd -  

end

$SRC/SHELLSCRIPTS/generatePotandDistDiff.csh $1 $2 $3 

cd $PWD
