#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set t=$1 
set s=$2 
set in1=$3.results.thresh$t.size$s.doiden0.onlyanno0
set in2=$3.results.thresh$t.size$s.doiden0.onlyanno1
set in3=$3.results.thresh$t.size$s.doiden1.onlyanno0
set in4=$3.results.thresh$t.size$s.doiden1.onlyanno1

set ANAME=`cat A.name`
set BNAME=`cat B.name`

$SRC/FRAGALWEB/makewebtablefromlist.pl -inf $in1 -out $in1.html -caption "A=$ANAME, B=$BNAME, Threshold for similarity =$t, length of fragment = $s, sorted based on average %similarity, Multiply index with 10 to get sequence starting position in original sequence "
$SRC/FRAGALWEB/makewebtablefromlist.pl -inf $in2 -out $in2.html -caption "A=$ANAME, B=$BNAME, Threshold for similarity =$t, length of fragment = $s, sorted based on average %similarity , Multiply index with 10 to get sequence starting position in original sequence"
$SRC/FRAGALWEB/makewebtablefromlist.pl -inf $in3 -out $in3.html -caption "A=$ANAME, B=$BNAME, Threshold for similarity =$t, length of fragment = $s,sorted based on average  %similarity+identity, only if annotated , Multiply index with 10 to get sequence starting position in original sequence"
$SRC/FRAGALWEB/makewebtablefromlist.pl -inf $in4 -out $in4.html -caption "A=$ANAME, B=$BNAME, Threshold for similarity =$t, length of fragment = $s, sorted based on average %similarity+identity , only if annotated, Multiply index with 10 to get sequence starting position in original sequence"
