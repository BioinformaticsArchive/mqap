#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set size=$1

set ANAME=`cat A.name`
set BNAME=`cat B.name`
$SRC/FRAGALWEB/makewebSingleLength.pl -outf mainlevel.$ANAME.$BNAME.html -thre 25 -thre 30 -thre 35  -size $size -title $ANAME.$BNAME

