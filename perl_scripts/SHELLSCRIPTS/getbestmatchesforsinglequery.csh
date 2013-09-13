#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set i = $1
set listref = $2


$SRC/SHELLSCRIPTS/newfile.csh YY 
$SRC/SHELLSCRIPTS/newfile.csh ZZ 
$SRC/SHELLSCRIPTS/newfile.csh POT 
$SRC/SHELLSCRIPTS/newfile.csh DIST

foreach ref ( ` cat $listref` )
    if(-e  $i/$i.$ref.pdb.out && !(-z $i/$i.$ref.pdb.out)) then 
		echo -n "$ref " >> YY 
		head -1  $i/$i.$ref.pdb.out >> YY 


		echo -n "AA: " >> ZZ 
		head -2  $i/$i.$ref.pdb.out | grep -v RESULT >> ZZ 
		$SRC/MISC/potential.seperate.pl -in $i/$i.$ref.potential.diff.txt -outf ffff

		echo -n "POT: " >> POT 
		cat ffff | grep BFILE >> POT 

		echo -n "DIST: " >> DIST 
		cat $i/$i.$ref.distance.diff.txt >> DIST 

	endif 
end
$SRC/MISC/concatfilePerline.pl YY ZZ -out PP
$SRC/MISC/concatfilePerline.pl PP POT -out QQ
$SRC/MISC/concatfilePerline.pl QQ DIST -out AA

$SRC/MISC/sort.pl -idx 4 -in AA -out list.ordered.scores
$SRC/MISC/makepdblistonly.pl -in list.ordered.scores -out list.ordered

#ANN list.ordered
