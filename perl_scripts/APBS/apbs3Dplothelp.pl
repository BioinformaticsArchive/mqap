my $TT = "TT";
unlink $TT ;
foreach my $i (1..11){
	my $list = "list.$i";
	unlink $list;
	system("ls | grep -v dir | grep -w SLICE$i > $list ");
    system("apbs3Dplot.pl -out $list.dat -lis $list");
	system (" echo \"$list.dat\" using 1:2:3, >> $TT");
}

