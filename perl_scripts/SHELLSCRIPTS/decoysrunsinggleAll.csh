#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set PWD = ` pwd`
set list = $1

setenv APBSDIR $APBSDIRDECOY/
setenv PDBDIR $PDBDIRDECOY/

foreach i (`cat $list`)
	cd $i 
	echo running $i 
	$SRC/SHELLSCRIPTS/decoysrunsingglelist.csh list short
	$SRC/SHELLSCRIPTS/decoysrunsingglelist.csh list full
	cd -
end 

head -1 ` ff "out.short" ` > ! HEADSHORT




