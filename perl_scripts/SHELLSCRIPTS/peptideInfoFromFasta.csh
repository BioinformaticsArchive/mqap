#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : list dir "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set fastadir = $2


foreach ref ( ` cat $listref` )
	#ls $fastadir/$ref.ALL* 
	if(! -e $fastadir/$ref.peptideinfo) then 
        pepstats -sequence $fastadir/$ref.ALL*  -stdout -auto > ! $fastadir/$ref.peptideinfo
	    echo wrote $fastadir/$ref.peptideinfo 
	    wc -l $fastadir/$ref.peptideinfo
	endif 
end

