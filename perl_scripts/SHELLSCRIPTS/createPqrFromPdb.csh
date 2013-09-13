#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listout = $2

foreach i ( ` cat $listref` )
  echo "Creating $i.pqr from PDB file $i"
  echo  pdb2pqr.py --chain --apbs-input --ff=parse --with-ph=7 $i $i.pqr
  pdb2pqr.py --chain --apbs-input --ff=parse --with-ph=5 $i $i.pqr
  echo $i.pqr >> $listout 
  cp $i.pqr $i.nocharge.pqr 
end

