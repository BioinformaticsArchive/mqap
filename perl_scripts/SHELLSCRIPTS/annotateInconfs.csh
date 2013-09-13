#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage :  <list> "
  exit 
endif 
#echo "PERLLIB = $PERLLIB ,  $BENCH_HOME = BENCH_HOME , BIN_HOME = $BIN_HOME , MGC_HOME = $MGC_HOME "

set PWD = ` pwd`
set list = $1
foreach i (`cat $list`)
    $SRC/3DMatch -outf ooo -pdb1 $i -outf oo -outconf $i.outconf.annotated -inconf $i*outconf -ann
end 

