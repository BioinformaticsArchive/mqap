#!/bin/csh -fv

if($#argv != 1  ) then 
  echo "Usage : "
    exit 
endif 

set out=$1

set outgnu=$out.gnuplot.scr
set outgnufpr=$out.gnuplot.fpr.scr
$SRC/SHELLSCRIPTS/newfile.csh $outgnu
$SRC/SHELLSCRIPTS/newfile.csh $outgnufpr
echo plot  \"$out.freqdist\" using 1:2 smooth bezier title \'Frequency distribution \'  with lines    lc 3  >> $outgnu 
echo pause 1000 >> $outgnu 
echo plot  \"$out.fpr2sens\" using 1:2 smooth bezier title \'Sensitivity/Fpr\'  with lines    lc 3  >> $outgnufpr
echo pause 1000 >> $outgnufpr
gnuplot < $outgnu &
gnuplot < $outgnufpr &
