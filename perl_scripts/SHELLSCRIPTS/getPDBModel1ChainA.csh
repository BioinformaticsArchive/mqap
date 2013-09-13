#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : protein name "
  exit 
endif 

if(-e  $PDBDIR/$1.pdb) then 
cp -f $PDBDIR/$1.pdb .
else
pdbget $1
endif 

getPDBModel1ChainA.pl -protein $1 -model
getPDBModel1ChainA.pl -protein $1 -chain $1-m0.pdb
\rm $1.pdb
mv -f $1-m0-c0.pdb $1.pdb 
\rm $1*-m*.pdb
