#!/bin/csh -f

if($#argv != 2) then 
  echo "Usage : <id>  <dist> "
  exit 
endif 

set i = $1
set dist = $2


cp -f $ANNDIR/$i.outconf.annotated . 

newfile.csh HHH
echo $i >> HHH 

createClosetoAnnotate.pl -list HHH -dist $dist -ann $cwd
cp -f $i.outconf.annotated.close $i.outconf.annotated.close.$dist
pepstats -sequence $i.ALL.$dist.fasta -stdout -auto > ! $i.$dist.peptideinfo

\rm HHH 


