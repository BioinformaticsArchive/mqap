#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set PWD = ` pwd`
set run = $1

cd $PWD/IMAGES
ls *.png > ! list 

cd $PWD/BASE
ls *.tiff > ! list 

mkdir -p $PWD/RESULTS

cd $PWD/RESULTS 
foreach i (`cat $PWD/BASE/list`)
	mkdir -p $i 
	cd $i 

	\cp -f $PWD/BASE/$i base.png
	ln -s $PWD/IMAGES/* . 
	mkdir -p found

	$SRC/IMAGE/3DprocessAmba.pl -in base.png -lis list -spec red -delta 0.314 -color white -dist 1.5

	cd ../
end 

cd $PWD
