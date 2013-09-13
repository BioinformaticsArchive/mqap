#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : ./delphi.csh  <list> <size>"
  exit 
endif 

set PWD = ` pwd`
set list = $1
set size = $2

foreach i (`cat $list`)
   set report = "$i.csh"
   \rm $report 
   touch $report
   echo $report 

   echo mkdir $i >> $report 
   echo cd $i >> $report
   

   echo unlink $i.prm  >> $report 
   echo unlink $i.sites.frc  >> $report 
   echo ln -s  /home/sandeepc/DownloadedTools/delphi/DELPHI_2004_LINUX_v2/charm22.crg .  >> $report 
   echo ln -s  /home/sandeepc/DownloadedTools/delphi/DELPHI_2004_LINUX_v2/charm22.siz .  >> $report 

   echo delphi.pl -in $i -size $size  >> $report 
   echo echo Running delphi ... result in result.$i >> $report 
   echo delphi $i.prm \> \& \! result.$i >> $report 
   echo cd - >> $report
   chmod 777 $report
end 

