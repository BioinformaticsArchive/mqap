#!/bin/csh -f
foreach i ( *.out )
echo 
echo 
echo $i 
grep ^\# $i | head -2 
end 
