#!/bin/csh -f

if($#argv != 9   ) then 
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
set protein = $9

mkdir -p $protein 

set listfile = "$scores/$protein.$tag.sorted"

# create top web page
annotate.pl -in ~/pdb_seqres.txt -list $listfile -out $protein/$protein.html  -cutoff 100 -html $html -scores -addto $protein \
            -header "Best macthes for Protein $protein"

## create log files if they dont already exist
foreach ref ( ` cat $listref` )
    #if(! -e $protein.$ref.html) then 
	      webCreateLogForOne.csh $ref $protein $3 $4 $5 $6 
	#endif 
end



