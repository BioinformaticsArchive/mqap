#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1



foreach ref ( ` cat $listref` )
  echo "Doiongg $ref"
  if(-e $ref.pdb.gz) then 
  	  gunzip $ref.pdb.gz 
  endif 

  if(-e $ref.pdb) then 
      $SRC/SHELLSCRIPTS/getPDBModel1ChainA.csh $ref

      if(! -e $ref/pot0.dx.atompot) then 
	      echo $ref > ! list 
	      apbs.csh list 
      endif 
  endif 
end

