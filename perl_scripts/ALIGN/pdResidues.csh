set list = $1
if(! -e "pd.CA") then 
   $SRC/ALIGN/escapist.pl -outf oooo -con $CONFIGGRP -lis $list 
endif 

set what=CA 
sort pd.$what > ! lll
\cp -f lll pd.$what 
addCounter.pl -out $what.mean -in pd.$what -idx 1
addCounter.pl -out $what.sd -in pd.$what -idx 2
addCounter.pl -out $what.num -in pd.$what -idx 3

set what=CB 
sort pd.$what | grep -v G > ! lll
\cp -f lll pd.$what 
addCounter.pl -out $what.mean -in pd.$what -idx 1
addCounter.pl -out $what.sd -in pd.$what -idx 2
addCounter.pl -out $what.num -in pd.$what -idx 3

cat  pd.$what | grep C > !  table.pd.$what.C 

set what=CN 
sort pd.$what > ! lll
\cp -f lll pd.$what 
addCounter.pl -out $what.mean -in pd.$what -idx 1
addCounter.pl -out $what.sd -in pd.$what -idx 2
addCounter.pl -out $what.num -in pd.$what -idx 3


if(! -e "pd.CBVarySeqDist") then 
    escapist.pl -outf pd.CBVarySeqDist -con $CONFIGGRP -lis $list
endif 


foreach i ( pd.single.*CN* )
    $SRC/MISC/frequencyDistributionAbs.pl -outf freq.$i -idx 1 -max 700 -delta 50 -start 200 -inf $i
	$SRC/MISC/freqdistAbs2Percent.pl -in freq.$i -out prob.freq.$i
end 

foreach i ( pd.single.*CB* )
    $SRC/MISC/frequencyDistributionAbs.pl -outf freq.$i -idx 1 -max 200 -delta 10 -start -200 -inf $i
	$SRC/MISC/freqdistAbs2Percent.pl -in freq.$i -out prob.freq.$i
end 

foreach i ( pd.single.*CA* )
    $SRC/MISC/frequencyDistributionAbs.pl -outf freq.$i -idx 1 -max 150 -delta 10 -start -150 -inf $i
	$SRC/MISC/freqdistAbs2Percent.pl -in freq.$i -out prob.freq.$i
end 



grep P pd.CA > ! table.prolineCA
createTexTable.pl -in table.prolineCA -out table.prolineCA.tex

grep C pd.CB > ! table.cysteineCB
createTexTable.pl -in table.cysteineCB  -out table.cysteineCB.tex

