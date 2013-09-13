#!/bin/csh -f

if($#argv != 3  ) then
  echo "Usage : "
    exit
	endif

set pqr=$1 
set outfile=$2
set pdb=$3

newfile.csh $outfile

set atom=$pdb.ORIG.pdb.pqr

echo read >> $outfile 
    echo mol pqr $pqr  >> $outfile
    echo mol pqr $atom      >> $outfile
echo end >> $outfile 

echo elec name inhom           >> $outfile 


    echo mg-auto              >> $outfile
	echo dime 129 161 129  >> $outfile 
	echo cglen 83.9086 102.2941 78.4414  >> $outfile 
	echo fglen 69.3580 80.1730 66.1420  >> $outfile 
    echo cgcent mol 2         >> $outfile
    echo fgcent mol 2         >> $outfile
    echo mol 1 >> $outfile 
    echo lpbe >> $outfile 
    echo bcfl sdh >> $outfile 
    echo pdie 20.00 >> $outfile 
    echo sdie 78.54 >> $outfile 
    echo srfm smol >> $outfile 
    echo sdens 40.0 >> $outfile 
    echo chgm spl2 >> $outfile 
    echo srad 1.40 >> $outfile 
    echo swin 0.30 >> $outfile 
    echo temp 298.15 >> $outfile 
    echo calcenergy total >> $outfile 
    echo calcforce no >> $outfile 
echo end >> $outfile

echo print energy inhom end >> $outfile 

echo quit >> $outfile 
