#!/bin/csh

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set what=$1 
set rad=$2 

#runRefExtractEasilyNamed.csh motif.$what list.A
#runRefExtractEasilyNamed.csh motif.$what list.C
#runRefExtractEasilyNamed.csh motif.$what list.D
#runRefExtractEasilyNamed.csh motif.$what list.PBP
#runRefExtractEasilyNamed.csh motif.$what list.ST


cat ` ff "*.SERLYS" ` > ! SERLYS

set REF=` cat motif.$what ` 
blase.pl -in SERLYS -out cumuscore.$what -pr $REF -lis list.blase -rad $rad


blaseNeedle.pl -lis list.blase
mkdir NEEDLE.$what
\mv -f *needle.out NEEDLE.$what 

blaseExtractAll.csh $what NEEDLE.$what

