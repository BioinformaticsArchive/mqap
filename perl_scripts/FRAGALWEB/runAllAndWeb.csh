#!/bin/csh -f

if($#argv != 5  ) then 
  echo "Usage : ./generaterep.csh  <impl dir> <file_having_list_of_designs> <tech - eg altera> <mode> <dirfortech - eg stratixii> "
  echo "You need to set ,  BENCH_HOME , BIN_HOME &  MGC_HOME "
  exit 
endif 

set thresh=$3 
set size=$4 
set arg=$5 

echo "fragmentcompare.pl -outfile results.out -in1 $1  -in2 $2  -thresh $thresh -process -onlyann 0 -doiden 0 -size $size -arg $arg"
fragmentcompare.pl -outfile results.out -in1 $1  -in2 $2  -thresh $thresh -process -onlyann 0 -doiden 0 -size $size -arg $arg
fragmentcompare.pl -outfile results.out -in1 $1  -in2 $2  -thresh $thresh -process -onlyann 0 -doiden 1 -size $size -arg $arg
fragmentcompare.pl -outfile results.out -in1 $1  -in2 $2  -thresh $thresh -process -onlyann 1 -doiden 0 -size $size -arg $arg
fragmentcompare.pl -outfile results.out -in1 $1  -in2 $2  -thresh $thresh -process -onlyann 1 -doiden 1 -size $size -arg $arg

createTexTable.pl -in A.sequences -out Aseq.tex
createTexTable.pl -in B.sequences -out Bseq.tex

foreach i ( cumu.results.*)
createTexTable.pl -in $i -out latex.$i.tex
end

foreach i ( aver.results.*)
createTexTable.pl -in $i -out latex.$i.tex
end


$SRC/FRAGALWEB/makewebfilesFRAGAL.csh $thresh $size aver
$SRC/FRAGALWEB/makewebfilesFRAGAL.csh $thresh $size cumu

