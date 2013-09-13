#!/bin/csh -f
if($#argv != 1  ) then
  echo "Usage : "
    exit
endif
set max = $1

foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  foreach what ( Polar Acidic Basic AcidBasic ALL)
	  	  newfile.csh $what.slope  
		  newfile.csh $what.outrsquare 
	  end 
end

newfile.csh learntable.dat
foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  foreach what (Polar Acidic Basic AcidBasic ALL)
	  	  echo fitting $dist $what
          promlinefit.pl -outslope $what.slope -inf output.$dist.local.$what.csv  -outrsquare $what.outrsquare -dist $dist -max $max -what $what
	  end 
end



foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  foreach what (Polar Acidic Basic AcidBasic ALL)
	       promLearntTable.pl  -out learntable.dat -in $what.slope 
	  end 
end

