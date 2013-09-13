#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : list scores"
  exit 
endif 

set PWD = ` pwd`
set list = $1
set scores = $2


newfile.csh info 

#setenv PDBDIR $PWD 
foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
    foreach i ( ` cat $list` )
		mkdir -p $i 
		cd $i
	    echo "Running createClose2ResiduesAndFastaForPromLearn.csh $i $dist"
        createClose2ResiduesAndFastaForPromLearn.csh $i $dist
		cd -
	end
end

	#promLearn.pl -dist $dist -protein $i -peptideinfo $i.$dist.peptideinfo -out info -scores $scores
