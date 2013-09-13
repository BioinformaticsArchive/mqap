#!/bin/csh -f

if($#argv != 6  ) then 
  exit 
endif 

# arg 3 is ignored

foreach i ( 3 4 5 6 7 8 )
     diffPairwise.pl -p1 $1 -p2 $2 -outf ooo -con $CONFIGGRP -rad $i -threshpd $4 -onlypolar $5 -tag $6 
end 

