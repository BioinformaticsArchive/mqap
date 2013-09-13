#!/bin/csh -f

if($#argv != 4) then 
  echo "Usage : <id> <inputfile> <dist> "
  exit 
endif 

set i = $1
set inputfile = $2
set dist = $3
set howmany = $4

set outdir = ANNOTATE.$howmany

mkdir -p $outdir

\rm $i.outconf.annotated 

if(! -e $outdir/$i.outconf.annotated) then 
   createCLASPinput.pl -list $inputfile -protein $i -out ooo -con $CONFIGGRP -howmany $howmany 
endif 

if(-e ooo) then 
    3DMatch -anno -outf jjj  -pdb $i -inconf ooo -outconf  $i.outconf.annotated
	\rm ooo 
    cat  $i.outconf.annotated
    \cp -f $i.outconf.annotated  $outdir
endif 

#newfile.csh HHH
#echo $i >> HHH 
#
#createClosetoAnnotate.pl -list HHH -dist $dist -ann $cwd
#cp -f $i.outconf.annotated.close $i.outconf.annotated.close.$dist
#pepstats -sequence $i.ALL.$dist.fasta -stdout -auto > ! $i.$dist.peptideinfo
#
#\rm HHH 


