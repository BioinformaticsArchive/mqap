#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set listref = $PWD/$1


foreach i ( ` cat $listref` )
    ann2simpleinput.pl -out ANNOTATE/$i.in -in ANNOTATE/$i.outconf.annotated
	createCLASPinput.csh $i ANNOTATE/$i.in 3 3 
	mv -f $i.outconf.annotated ANNOTATE/$i.outconf.annotated
end

