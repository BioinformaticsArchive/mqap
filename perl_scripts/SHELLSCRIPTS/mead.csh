#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : ./mead.csh  <list>"
  exit 
endif 

set PWD = ` pwd`
set list = $1

foreach i (`cat $list`)
   set report = "$i.csh"
   echo $report  llll
   \rm $report 
   touch $report

   echo mkdir $i >> $report 
   echo cd $i >> $report
   echo python /home/sandeepc/DownloadedTools/pdb2pqr/pdb2pqr-1.6/pdb2pqr.py \-\-ff=AMBER /media/disk-1/PDBS.LINK.ALL//$i.pdb $i.pqr  >> $report 

   echo unlink $i.ogm  >> $report 
   echo echo ON_GEOM_CENT 201 1.0 \> $i.ogm  >> $report 

   echo $SRC/mead.pl -in $i -onatom >> $report 
   #echo mead.pl -in $i >> $report 
   echo echo Running Mead... result in result.$i >> $report 
   echo potential -epsin 1 -epsext 80 -blab2 $i \> \& \! result.$i >> $report 
   echo cd - >> $report
   chmod 777 $report
end 

