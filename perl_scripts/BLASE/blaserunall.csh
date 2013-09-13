#!/bin/csh 

if($#argv != 2  ) then 
  echo "Usage : "
  exit 
endif 

set rad=$1
set list=$2

\rm *fasta cumuscore*
blaseAnnList.csh $list

blaseRunmotifs.csh A $rad
#blaseRunmotifs.csh C $rad
#blaseRunmotifs.csh D $rad



newfile.csh ALL.fasta
foreach ref ( ` cat list.blase `)
    cat $ref.fasta >> ALL.fasta 
end 

set fastafile=FASTA.ANN.$rad
blaseAnnotateFasta.pl -outf $fastafile -in ALL.fasta  

set fastafilealn=$fastafile.aln
clustalw -INFILE=$fastafile -OUTFILE=$fastafilealn -gapopen=2
