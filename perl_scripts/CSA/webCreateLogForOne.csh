#!/bin/csh -f

if($#argv != 6  ) then 
  echo "Usage : "
  exit 
endif 

set PWD = ` pwd`
set ref = $1
set query = $2
set results = $3
set extract = $4
set anndir = $5
set scores = $6


set outfile = $query/$query.$ref.html

rm -f $outfile
touch $outfile

set pdbout = "$extract/$query/$query.$ref.pdb.out"
set annout = "$anndir/$ref.outconf.annotated"

if(-e $pdbout && -e $$extract/$query/$query.$ref.log) then 

     webMakePageHtml.pl -in $annout -out outtemp -header "Motif for $ref"
     cat outtemp >> $outfile
     rm outtemp 
     
     
     sed -e '1,/RESULT/d' -e '/RESULT/,$d' $pdbout  > ! outtemp1
     #awk ' /RESULT/ {flag=1;next} /RESULT/{flag=0} flag { print }' $pdbout > ! outtemp1
     webMakePageHtml.pl -in outtemp1 -out outtemp -header "PREDICTED MOTIFS in $query using a motif from $ref"
     cat outtemp >> $outfile
     rm outtemp 
     
     awk ' /NEWS/ {flag=1;next} /NEWS/{flag=0} flag { print }' $extract/$query/$query.$ref.log > ! outtemp1
     webMakePageHtml.pl -in outtemp1 -out outtemp -header "Potential differences between pairs of residues in best scoring motif"
     cat outtemp >> $outfile
     rm outtemp 
     
     \rm outtemp1

endif
