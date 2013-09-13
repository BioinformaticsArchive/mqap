#!/bin/csh -f

if($#argv != 6  ) then 
  exit 
endif 



diffPairwise.pl -p1 $1 -p2 $2 -outf ooo -con $CONFIGGRP -rad $3 -threshpd $4 -onlypolar $5 -tag $6

exit  
cd FigPD 
./do.sh 
cd ..
cd FigDD 
./do.sh 
cd ..
