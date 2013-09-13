#!/bin/csh -f

if($#argv != 3  ) then 
  echo "Usage : id < which says global or local> <dist> <fastadir> "
  exit 
endif 

set PWD = ` pwd`
set id = $1
set dist = $2
set fastadir = $3



promiscuity.pl -in score.$dist -scale
sort.pl -in score.$dist.scaled -out sorted.$dist.csv -idx 2 > & /dev/null 
promiscuity.pl -in sorted.$dist.csv -dist $dist -id $id -fasta $fastadir
foreach i ( output*$dist*$id*) 
	 	 echo $i 
	     sort -n $i > ! TTT 
	     mv -f TTT $i
end

