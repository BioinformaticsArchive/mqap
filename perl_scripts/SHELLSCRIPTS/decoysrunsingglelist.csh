#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set PWD = ` pwd`
set list = $1
set tag = $2

setenv APBSDIR $APBSDIRDECOY/
setenv PDBDIR $PDBDIRDECOY/

foreach i (`cat $list`)
	cd $i 
	pwd 
	echo "running  $SRC/SHELLSCRIPTS/decoysrunsinggle.csh list $tag. logged in log "
	$SRC/SHELLSCRIPTS/decoysrunsinggle.csh list $tag > & ! log.$tag
	cd -
end 


foreach j ( 2 5 8 11 )
	newfile.csh spec.$j.$tag
end

foreach i (`cat $list`)
    foreach j ( 2 5 8 11 )
	   cat $i/spec.$j.$tag >> spec.$j.$tag
	end
end 

foreach j ( 2 5 8 11 )
	addCounter.pl -in spec.$j.$tag -out graph.$j.$tag
end

head -1 ` ff "out.short" ` > ! HEADSHORT

