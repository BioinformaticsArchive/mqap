#!/bin/csh -f
foreach i ( *.pdb )
echo $i 
$SRC/3DMatch -outf $i.out -pdb1 $i -fin -inconf outconf.1
end 
