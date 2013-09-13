#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage :  <list>  "
  exit 
endif 

set list = $1

foreach i ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	\rm -rf ANNOTATE
	cp -r ANNOTATE.$i ANNOTATE
    if(! -e results.$i/score.$i) then 
		echo $i
		sleep 1 
        cleanscores.csh Extract.list.all.list.all/
        $SRC/CSA/runRefExtractEasilyNamed.csh $list $list
        mkdir results.$i
        cp -f $list score.$i results.$i
    endif
end 
