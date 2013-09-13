#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : protein name "
  exit 
endif 

cp -f $PDBDIR/$1.pdb .
writeSeperateChains.pl -protein $1 -model -outf $2
writeSeperateChains.pl -protein $1 -chain $1-m0.pdb -outf $2
sort $2 > ! kkkkk 
uniq kkkkk > ! $2 
#\rm $1.pdb
#mv -f $1-m0-c0.pdb $1.pdb 
#\rm $1*-m*.pdb
