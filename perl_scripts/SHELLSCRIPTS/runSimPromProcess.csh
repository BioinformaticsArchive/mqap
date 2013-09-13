#!/bin/csh -f

if($#argv != 2  ) then 
  echo "Usage : <dist> samplesize "
  exit 
endif 

set n = $1
set samplesize = $2

set PWD = ` pwd ` 

newfile.csh scores

foreach i ( results.*)
    cd $i
	promiscuity.pl -in score.$n -scale
	cat score.$n.scaled >> $PWD/scores 
	cd -
end 

promiscuity.pl -in scores -stat $samplesize -outfile scores.$n.stat -population score.$n.scaled.popu

sort.pl -in data.csv -out data.sorted.csv -idx 1 > & ! /dev/null 

head -20 data.sorted.csv > ! jjj 
removeafter.pl -out head -in jjj -after ","

tail -20  data.sorted.csv > ! jjj 
removeafter.pl -out ttt -in jjj -after ","
reverseorder.pl -out tail -in ttt

ANN tail > & ! /dev/null 
mv -f llllll best.tex
ANN head > & ! /dev/null 
mv -f llllll worst.tex

$SRC/MISC/frequencyDistribution.pl -out oo.csv -in data.sorted.csv -max 1 -delta 0.01

