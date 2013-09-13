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

mkdir -p $finaldir

foreach ref ( ` cat $listref` )
echo cd $dir/$ref
  cd $dir/$ref
  mkdir -p $finaldir/$ref
  foreach query ( ` cat $listquery` )
       if(  -e $query.pdb.out && ! -e $finaldir/$ref/$query.pdb.out   ) then
           \cp  -f $query.pdb.out $finaldir/$ref
       endif
  end
  cd -
end
