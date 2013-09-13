#!/bin/csh -f

set SRC = ~/Bio/Code/perl_scripts
if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $PWD/$1
set listquery = $PWD/$2
set dir = $PWD/$3
set finaldir = $PWD/$4

mkdir -p $dir/$finaldir

foreach ref ( ` cat $listref` )
  cd $dir/$ref 	
  foreach query ( ` cat $listquery` )
       if( ! -e $query.pdb.out   ) then 
	   	   cp $query.pdb.out ../$finaldir
	   endif 
	       
  endif 
end
cd -


