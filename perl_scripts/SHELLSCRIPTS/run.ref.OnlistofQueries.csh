#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : <cmd> list refpdb motif potindex refpotindex "
  exit 
endif 

set list = $1 
set pdb = $2 
set motif = $3 
set index = $4 
set refpotindex = $5 




foreach i (`cat $list`)
	\rm -rf $i
	mkdir -p $i 
	cd $i 
    $SRC/CLASP -ref $pdb -qu $i -motif $motif -potindex $index -howman 10 -refpotindex $refpotindex
	cd -
end 

