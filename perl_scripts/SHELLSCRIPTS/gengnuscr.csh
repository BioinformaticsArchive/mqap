#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : "
  exit 
endif 

set num = $1
set what = $2
set property = $3

set out = gnu.$num.$what.$property.scr

echo set term jpeg > ! $out
echo set output \"output.$num.$what.$property.jpg\" >> $out
echo plot  \"output.$num.$what.$property\" using 1:2 smooth bezier title \"Active site residues $num $what $property\"  with lines lc 4   >>  $out

gnuplot  $out

