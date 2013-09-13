#!/bin/csh -f

foreach what ( Polar AcidBasic)
     newfile.csh  outstat.$what
     foreach dist ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )
	       /home/sandeepc/oper_scripts/scripts//mean.pl -inf output.$dist.local.$what.csv -idx 1 -print $dist >> outstat.$what
     end
end

~/add2Tables.pl -outf uuu -in1 outstat.Polar -in2 outstat.AcidBasic
createTexTable.pl -in uuu -outf table.tex


