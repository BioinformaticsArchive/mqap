#!/bin/csh -f
limit coredumpsize 0
mkdir -p 3Q82
cd 3Q82
unlink 3Q82.log
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts//APBS/pdb2pqr.pl -forcefield parse -protein 3Q82 -out 3Q82.pqr
echo STTTT status = $status
ls
echo ============
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts//APBS/apbs.pl -in 3Q82.in -out 3Q82.apbs.mod.in
echo $PWD Running apbs ... result in 3Q82.log
echo ok this is the probl apbs ... result in 3Q82.log
echo jffffffffok this is the probl apbs ... result in 3Q82.log
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts/EXTERNALTOOLS//apbs 3Q82.apbs.mod.in
ls
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts/EXTERNALTOOLS//pqr2csv 3Q82.pqr 3Q82.csv
foreach s ( pot*dx )
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts/EXTERNALTOOLS//multivalue 3Q82.csv $s $s.atompot
end
unlink result
touch result
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts//APBS/apbsGetVolt.pl -resultfile /home/results/Results.betalactamase/ALL.good//3Q82.pdb.out -proteinName 3Q82 -pqr 3Q82.pqr -out result.0 -pot pot0.dx.atompot -index 0
/home/sandeepc/Bio/Code/perl_scripts/perl_scripts//APBS/apbsGetVolt.pl -resultfile /home/results/Results.betalactamase/ALL.good//3Q82.pdb.out -proteinName 3Q82 -pqr 3Q82.pqr -out result.1 -pot pot1.dx.atompot -index 1
rm -f pot*dx
cd -
echo done
