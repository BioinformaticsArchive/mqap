#!/bin/csh -f
if($#argv != 1  ) then 
  echo "Usage : "
endif 



#foreach dist ( 5 6 7 12 )
foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
    cd results.$dist

    $SRC/SHELLSCRIPTS/promiscuous.csh local $dist ~/TGZ/all2all/ANNOTATE.$dist 
	#gengnuscr.csh $dist local Polar
	#gengnuscr.csh $dist local Basic
	#gengnuscr.csh $dist local Acidic
	#gengnuscr.csh $dist local Molecular

    $SRC/SHELLSCRIPTS/promiscuous.csh global $dist $FASTADIR
	#gengnuscr.csh $dist global Polar
	#gengnuscr.csh $dist global Basic
	#gengnuscr.csh $dist global Acidic
	#gengnuscr.csh $dist global Molecular


	cd - 
end
