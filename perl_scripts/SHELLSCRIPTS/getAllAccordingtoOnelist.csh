#!/bin/csh -f
if($#argv != 1  ) then
  echo "Usage : "
    exit
endif
set listref = $1

foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	newfile.csh list.$dist.sortedwith
    foreach ref ( ` cat $listref` )
	     grep $ref results.$dist/sorted.$dist.csv >> list.$dist.sortedwith
    end
end



foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
		 perl ~/addCounter.pl -out lll.$dist -inf list.$dist.sortedwith -idx 2
end
