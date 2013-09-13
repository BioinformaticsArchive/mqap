#!/bin/csh -f

if($#argv != 1  ) then 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set list = $1

foreach i (`cat $list`)
mv ANNOTATE/$i.outconf.annotated ANNOTATE/$i.outconf.annotated.org
convert2Groups.pl -in ANNOTATE/$i.outconf.annotated.org -out ANNOTATE/$i.outconf.annotated
end 

