#!/bin/csh -f

if($#argv != 2  ) then
  echo "Usage : ./run.csh  <list> <outconf> "
  exit
endif


set list=$1
set outconf=$2 
set pwd=`pwd`

foreach i ( ` cat $list ` )
echo \#\!/bin/csh \-f > ! /tmp/sandeepc
$SRC/3DMatch -pdb $i -outf $i.pdb.out -incon $outconf -find


#exit 

end

