#!/bin/csh -f

if($#argv != 8  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set listref = $1
set listquery = $2
set results = $3
set extract = $4
set anndir = $5
set scores = $6
set html = $7
set tag = $8



# create top web page
$SRC/PDBSEQRES/annotate.pl -in $SRC/pdb_seqres.txt -list $listquery -out query.$tag.html  -cutoff 100 -html $html -header "List of Proteins in which CLASP has searched for motifs"


foreach query ( ` cat $listquery` )
    webCreateOneQuery.csh $1 $2 $3 $4 $5 $6 $7 $8 $query
end
