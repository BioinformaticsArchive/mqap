#!/bin/csh -f

if($#argv != 1  ) then 
  echo "Usage : "
  exit 
endif 

set image=`cat ref.txt`

$SRC/IMAGE/3Dprocess.pl -in $image -color blue -color red -list list -delta 0.314 -specif red 
$SRC/IMAGE/3Dprocess.pl -in $image -color blue -color red -list list -delta 0.314 -specif blue

cat red.rawdata blue.rawdata > ! rawdata

$SRC/IMAGE/3Dnormalize.pl -lis rawdata -in red.rawdata -out red.rawdata.normal
$SRC/IMAGE/3Dnormalize.pl -lis rawdata -in blue.rawdata -out blue.rawdata.normal


$SRC/MISC/frequencyDistributionAbs.pl -outf red.freq -idx 1 -max 1 -delta 0.1 -start 0 -in red.rawdata.normal
$SRC/MISC/frequencyDistributionAbs.pl -outf blue.freq -idx 1 -max 1 -delta 0.1 -start 0 -in blue.rawdata.normal

$SRC/MISC/freqdistAbs2Percent.pl -in red.freq -out prob.red.freq
$SRC/MISC/freqdistAbs2Percent.pl -in blue.freq -out prob.blue.freq


