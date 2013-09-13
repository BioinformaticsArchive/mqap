#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 



set PWD = ` pwd`
set run = $1
set list = $PWD/$2
##set list = $2
set tech = $3
set deformodgen = $4
set dirfortech = $5

set report = ${run}_report_${deformodgen}_${tech}_${dirfortech}.txt
set log = ${run}.log

foreach l ( a b c 123 456 red blue green ) 
  if( ! -e datafile.$l.out ) then 
      runprog < datafile.$l.in > datafile.$l.out 
  endif 
end




setenv PERLLIB $PERLLIB
cd $dirfortech
setenv TEST_HOME "$BENCH_HOME/$dirfortech"
\rm $report >& /dev/null
touch $report >& /dev/null

set PWD = ` pwd`
echo "Creating Report : $PWD/$report"

foreach i (`cat $list`)
	echo -n "Design: $i : "
	${REGR_HOME}/runregrsingle.csh $i
	echo ""
end 

echo "Created Report : $PWD/$report"
cd - 
