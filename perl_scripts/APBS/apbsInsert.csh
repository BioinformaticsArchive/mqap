#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : ./apbsInsert.csh  <list>  <pdb> <size= 1+ number of residues> "
  exit 
endif 

set PWD = ` pwd`
set list = $1
set i = $2
set size = $3

foreach insert (`cat $list`)
   set report = "$insert.csh"
   \rm $report 
   touch $report
   echo $report 

   set log = "$insert.log"
   set tmppqr = "$i.tmp.pqr"
   set pqr = "$i.pqr"
   set infile = "$i.in"
   set infilemod = "$i.apbs.mod.in"

   echo \#\!/bin/csh \-f >> $report 
   echo limit coredumpsize 0 >> $report 
   echo mkdir -p $insert.dir >> $report 
   echo cd $insert.dir >> $report
   

   echo unlink $infile  >> $report 
   echo unlink $infilemod  >> $report 
   echo unlink $log  >> $report 

   #echo pdb2pqr.py  --chain --apbs-input --ff=parse $PDBDIR/$i.pdb $pqr  >> $report 
   echo pdb2pqr.py  --chain --apbs-input --ff=parse /home/ws18/DATA/apbs.2G2U.testcharge/$i.pdb $pqr  >> $report 
   echo $SRC/APBS/apbsInsert.pl -in $insert -out $tmppqr -pqr $pqr  >> $report 
   echo unlink $pqr  >> $report 
   echo mv $tmppqr $pqr  >> $report 

   echo apbs.pl -in $infile -out $infilemod   >> $report 
   echo echo Running apbs ... result in $log >> $report 
   echo apbs $infilemod \> \& \! $log >> $report 

   echo pqr2csv $pqr $i.csv  >> $report 
   echo foreach s \( pot\*dx \)  >> $report 
       echo multivalue $i.csv \$s \$s.atompot   >> $report 
   echo end  >> $report 

   echo unlink result  >> $report 
   echo touch result  >> $report 
   echo $SRC/apbsGetVolt.pl -in $i -pqr $pqr -out result -pot pot1.dx.atompot -extra >> $report 
   echo $SRC/apbsParseOut.pl -out results.cons -in result -size $size >> $report


   echo cd - >> $report
   chmod 777 $report

end 

