#!/bin/csh -f

if($#argv != 3  ) then 
   "Usage : "
  exit 
endif 

set PWD = ` pwd`
set ref = $1
set query = $2
set extractdir = $3


cat ANNOTATED/$ref.outconf.annotated
echo ================= $extractdir/$query/$query.$ref.pdb.out ===================================
cat $extractdir/$query/$query.$ref.pdb.out
echo ================= $extractdir/$query/$query.pdb.out ===================================
cat $extractdir/$query/$query.pdb.out
echo ===================================
cat $extractdir/$query/$query.$ref.log
