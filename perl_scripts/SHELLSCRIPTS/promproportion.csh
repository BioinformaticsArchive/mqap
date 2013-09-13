#!/bin/csh -f
if($#argv != 2  ) then
  echo "Usage : "
    exit
endif
set promvalue = $1
set P = $2

foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  #foreach what ( Polar Acidic Basic AcidBasic ALL)
	  foreach what ( Polar AcidBasic )
	  	  newfile.csh $what.proportion  
	  	  newfile.csh $what.$P.sigma  
	  	  newfile.csh $what.$P.z  
	  	  newfile.csh $what.$P.p  
	  	  newfile.csh $what.$P.percent  
	  end 
end

newfile.csh number
foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  #foreach what (Polar Acidic Basic AcidBasic )
	  foreach what (Polar AcidBasic )
	  	  echo proportion $dist $what
          promproportion.pl -inf output.$dist.local.$what.csv  -dist $dist  -what $what -promvalue $promvalue  -outf ooo  -P $P -reverse 0
	  end 
end



#foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	  #foreach what (Polar Acidic Basic AcidBasic ALL)
	       #promLearntTable.pl  -out learntable.dat -in $what.slope 
	  #end 
#end

