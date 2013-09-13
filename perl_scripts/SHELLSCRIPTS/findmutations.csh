#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 


diffPairwise.pl -p1 $1 -p2 $2 -outf ooo -con $CONFIGGRP -rad 1 -threshpd 150 -tag All4 -onlypolar 1
\rm *All4* 
\rm *.PD 
#\rm mean*

