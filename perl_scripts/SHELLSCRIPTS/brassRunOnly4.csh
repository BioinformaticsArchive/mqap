#!/bin/csh

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set thresh = $1

#foreach i (3 4 5)
foreach i (4)
	mkdir -p cd list.$i.out 
	cd list.$i.out ;
	\rm *brass.out
	cd - 
    $SRC/SHELLSCRIPTS/brass.csh list.$i $thresh
end


#cat ./list.5.out/sorted.out ./list.3.out/sorted.out ./list.4.out/sorted.out > ! PPP
cat ./list.4.out/sorted.out > ! PPP
sort.pl -idx 1 -in PPP -out PPP.$thresh.sorted
makepdblistonly.pl -in PPP.$thresh.sorted -out PPP.$thresh.sorted.pdb 
#ANN PPP.$thresh.sorted.pdb
