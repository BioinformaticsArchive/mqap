#!/bin/csh 

if($#argv != 1  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set list = $1
set PDBDIR = /home/data/pdbs/


foreach i (`cat $list`)
	if(! -e $PDBDIR/$i.pdb) then 
        PDBGET $i
	    \mv -f $i.pdb $PDBDIR
	endif 
end 

foreach i (`cat $list`)
	getPDBModel1ChainA.csh $i
	\mv -f $i.pdb $PDBDIR
end 

apbs.csh $list 
