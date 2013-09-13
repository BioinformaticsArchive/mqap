#!/bin/csh -fv


cd $FASTADIR 
$SRC/BIOPERL/getFastaNotExisting.pl -out run.csh
source run.csh 
