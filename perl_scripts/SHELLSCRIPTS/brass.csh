#!/bin/csh -f

if($#argv != 2 ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd `
set listref = $PWD/$1
set threshold = $2
set dir = $listref.out
set logfile = log.out
mkdir -p $dir 


cd $dir 

mkdir ANNOTATE
\rm ANNOTATE/*

\cp -r -f $PWD/ANNOTATE/*.outconf* ANNOTATE 
foreach i ( ` cat $listref` )
   echo $i > ! list.$i 
   if(! -e Extract.list.$i.list.$i) then 
	  echo Running CLASP on $i. Log in $i.clasp.log
      runRefExtractEasilyNamed.csh list.$i list.$i  0 
      #runRefExtractEasilyNamed.csh list.$i list.$i > & ! $i.clasp.log 
   endif 
end


foreach i ( ` cat $listref` )
   if(! -e $i.brass.out) then 
        ann2simpleinput.pl -out $PWD/ANNOTATE/$i.in -in $PWD/ANNOTATE/$i.outconf.annotated
	    echo Running Brass on $i. Log in $i.log
	    brass.pl -thresh $threshold -resul Extract.list.$i.list.$i/$i/$i.$i.pdb.out -list $PWD/ANNOTATE/$i.in -outf $i.brass.out -conf $CONFIGGRP -pro $i -rad2 7 -rad1 7 -muta $i.mutate   
    endif
end

newfile.csh $logfile
foreach i ( ` cat $listref` )
    cat  $i.brass.out >> $logfile
end 

sort.pl -idx 1 -in log.out -out sorted.out
brassScale.pl -in sorted.out -out ppp
makepdblistonly.pl -in ppp -out list.pdb
annotate.pl -mapping -in ~/pdb_seqres.txt  -out llllll -cutoff 100 -list list.pdb -anndis 5 ; 



echo Output in $dir/sorted.out 
cd - 
