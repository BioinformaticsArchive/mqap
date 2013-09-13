#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set ref = $1
set listquery = $2

newfile.csh YY 
newfile.csh ZZ 
newfile.csh POT 
newfile.csh DIST 
foreach i ( ` cat $listquery` )
    if(-e  $i/$i.$ref.pdb.out && !(-z $i/$i.$ref.pdb.out)) then 
		echo -n "$i " >> YY 
		head -1  $i/$i.$ref.pdb.out >> YY 


		echo -n "AA: " >> ZZ 
		head -2  $i/$i.$ref.pdb.out | grep -v RESULT >> ZZ 

		potential.seperate.pl -in $i/$i.$ref.potential.diff.txt -out ffff

		echo -n "POT: " >> POT 
		cat ffff | grep BFILE >> POT 

		echo -n "DIST: " >> DIST 
		cat $i/$i.$ref.distance.diff.txt >> DIST 

	endif 
end
concatfilePerline.pl YY ZZ -out PP
concatfilePerline.pl PP POT -out QQ
concatfilePerline.pl QQ DIST -out AA

sort.pl -idx 4 -in AA -out list.ordered.scores
makepdblistonly.pl -in list.ordered.scores -out list.ordered

#ANN list.ordered
