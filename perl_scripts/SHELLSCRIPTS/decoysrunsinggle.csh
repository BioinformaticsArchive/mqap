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
set outfile = out.$tag

setenv APBSDIR $APBSDIRDECOY/
setenv PDBDIR $PDBDIRDECOY/

foreach i (`cat $list`)
	if(! -e $outfile) then 
         ln -s ~/pd.C* .
	     $SRC/ALIGN/escapist.pl -outf $outfile -con $CONFIGGRP -lis list -score pd.CB.score.$tag
	endif 
end 


#$SRC/ALIGN/specfpr.pl -out zscores -li ~/listin -idx 20

# CA pd 
#$SRC/ALIGN/specfpr.pl -out zscores -li ~/listin -idx 11

# CB only 
foreach i ( 2 5 8 11 )
newfile.csh  spec.$i.oooo
newfile.csh  spec.$i
$SRC/ALIGN/specfpr.pl -out zscores -in $outfile -idx $i -tag $tag
end 



