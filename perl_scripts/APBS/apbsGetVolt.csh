#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : ./apbsGetVolt.csh  <list> <reportfile> <apbsdir> <resultsdir> <index> "
  exit 
endif 

set PWD = ` pwd`
set list = $1
set report = $PWD/$2
set dir = $3
set resultdir = $4
set index = $5

   \rm $report 
   touch $report
   echo $report 

foreach i (`cat $list`)

    cd $dir/$i 
	echo Runnning apbsGetVolt.pl -protein $i -pqr $i.pqr -out $report -pot pot1.dx.atompot -index $index -resultfile $resultdir/$i.pdb.out
    $SRC/APBS/apbsGetVolt.pl -protein $i -pqr $i.pqr -out $report -pot pot1.dx.atompot -index $index -resultfile $resultdir/$i.pdb.out
    cd -
   
end 

