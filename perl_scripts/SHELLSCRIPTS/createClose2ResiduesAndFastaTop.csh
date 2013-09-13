#!/bin/csh -f
if($#argv != 2 ) then
  echo "Usage : anndir list "
  exit
endif

set anndir = $1
set list = $2
set PWD = ` pwd ` 


#foreach dist ( 1 )
foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
    cp -r $anndir ANNOTATE.$dist	
	cd ANNOTATE.$dist
    #foreach i ( *.outconf.annotated)
    $SRC/SHELLSCRIPTS/createClose2ResiduesAndFasta.csh $list $dist $PWD/ANNOTATE.$dist
	#end 

	cd - 
end
