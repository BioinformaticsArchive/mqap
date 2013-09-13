#!/bin/csh -f

if($#argv != 4  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set pdb=$1
set resnum=$2
set orig=$3
set restype=$4
set list=pdb.list
set outlist=pdb.pqr.list

cd $PWD 
newfile.csh $list
newfile.csh $outlist

echo "Replace type"
replaceType.pl -outf $pdb.CHAN.pdb -pdb $pdb -resn $resnum -newtype $restype

cp -f $PDBDIR/$pdb.pdb $pdb.ORIG.pdb
echo $pdb.ORIG.pdb >> $list 
echo $pdb.CHAN.pdb >> $list 

echo "Create pqr from pdb "
createPqrFromPdb.csh $list $outlist


foreach i ( ` cat $outlist` )
	cat $i | grep "$orig\s*A\s*$resnum" > NUM.$i
	cat $i | grep "$restype\s*A\s*$resnum" >> NUM.$i
end

\rm $pdb.in
foreach i ( *.pqr )
  createIn.csh $i $i.in $pdb 
end

