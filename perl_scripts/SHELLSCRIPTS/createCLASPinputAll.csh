#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 

set list=$1 
set howmany=$2
set dir=$3

newfile.csh log
foreach i (`cat $list`)
    createCLASPinput.csh $i $dir/$i.CSA.outconf 44 $howmany	>>  & log 
end 

