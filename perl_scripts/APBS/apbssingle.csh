#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./apbssingle  pdbid "
  exit 
endif 

set i = $1 


   set report = "$i.csh"
   \rm $report 
   touch $report
   echo $report 

   set log = "$i.log"
   set pqr = "$i.pqr"
   set infile = "$i.in"
   set infilemod = "$i.apbs.mod.in"

   echo \#\!/bin/csh \-f >> $report 
   echo limit coredumpsize 0 >> $report 
   echo mkdir -p $i >> $report 
   echo cd $i >> $report
   

   #echo unlink $infile  >> $report 
   #echo unlink $infilemod  >> $report 
   echo unlink $log  >> $report 
   #echo unlink $pqr  >> $report 

   echo $SRC/APBS/pdb2pqr.pl -forcefield parse -protein $i -out $pqr  >> $report 
   echo echo STTTT status = \$status  >> $report 
   echo ls  >> $report 
   echo echo ============  >> $report 

   echo $SRC/APBS/apbs.pl -in $infile -out $infilemod   >> $report 
   echo echo \$PWD Running apbs ... result in $log >> $report 
   echo echo ok this is the probl apbs ... result in $log >> $report 
   echo echo jffffffffok this is the probl apbs ... result in $log >> $report 
   #echo $MYPATH/apbs $infilemod \> \& \! $log >> $report 
   echo $MYPATH/apbs $infilemod >> $report 
   echo ls >> $report 

   echo $MYPATH/pqr2csv $i.pqr $i.csv  >> $report 
   echo foreach s \( pot\*dx \)  >> $report 
       echo $MYPATH/multivalue $i.csv \$s \$s.atompot   >> $report 
   echo end  >> $report 

  echo unlink result  >> $report
  echo touch result  >> $report
  echo $SRC/APBS/apbsGetVolt.pl -resultfile $RESULTDIR/$i.pdb.out -proteinName $i -pqr $pqr -out result.0 -pot pot0.dx.atompot -index 0 >> $report
  echo $SRC/APBS/apbsGetVolt.pl -resultfile $RESULTDIR/$i.pdb.out -proteinName $i -pqr $pqr -out result.1 -pot pot1.dx.atompot -index 1 >> $report
  echo \rm -f pot\*dx>> $report
  echo \rm -f $i.apbs.mod.in $i-input.p io.mc result $i.in >> $report

  source $SRC/APBS/moveapbsfiles.csh




   echo cd - >> $report
   echo echo done >> $report
   chmod 777 $report
   source $report
   unlink $report


