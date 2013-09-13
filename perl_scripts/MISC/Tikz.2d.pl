#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;

use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($infile,$outfile,$which_tech,$listfile);
my ($xlabel,$ylabel);
$xlabel = "xlabel";
$ylabel = "ylabel";
my (@expressions);
my $howmany = 100000 ;
my $id ;
GetOptions(
            "which_tech=s"=>\$which_tech ,
            "infile=s"=>\$infile ,
            "listfile=s"=>\$listfile ,
            "xlabel=s"=>\$xlabel ,
            "ylabel=s"=>\$ylabel ,
            "outfile=s"=>\$outfile ,
            "id=s"=>\$id ,
            "expr=s"=>\@expressions,
            "howmany=i"=>\$howmany ,
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a id => option -id ") if(!defined $id);
my $CNT = 0 ; 
my ($RESULTDIR,$PDBDIR,$FASTADIR) = util_SetEnvVars();
my $PWD = cwd;
usage( "Need to give a listfile -option -listfile which lists all the data file  ") if(!defined $listfile);

my @colors = qw ( red blue green yellow purple magenta );
` mkdir -p $id ; cd $id ; ln -s ~/R/* .  ` ; 
$outfile = "$id/$id.tex";
my $ofh = util_write($outfile);


my @list= util_read_list_words($listfile);
my $list = {};
map { $list->{$_} = 1 ; } @list ;

print $ofh "\\documentclass{article} \n";
print $ofh "\\usepackage{tikz} \n";

print $ofh "\\usepackage{pgfplots} \n";
print $ofh "\\usepackage{verbatim} \n";


print $ofh "\\usepgfplotslibrary{groupplots} % LTEX and plain TEX \n";
print $ofh "\\usepgfplotslibrary[groupplots] % ConTEXt \n";
print $ofh "\\usetikzlibrary{pgfplots.groupplots} % LTEX and plain TEX \n";
print $ofh "\\usetikzlibrary[pgfplots.groupplots] % ConTEXt \n";


print $ofh "\\begin{document} \n";
print $ofh "\\pagestyle{empty} \n";

print $ofh "\\begin{tikzpicture} \n";
    print $ofh "\\begin{axis}[ \n";
		print $ofh "grid=major, \n";
        print $ofh "xlabel=$xlabel, \n";
        print $ofh "ylabel=$ylabel] \n";

	my $cnt = 0; 
    foreach my $file (@list){
		  my $color = $colors[$cnt++];
		  my $fullfile = "$PWD/$file" if(!($file =~ /^\//)); 
          print $ofh "\\addplot[smooth,color=$color] file {$fullfile} ; \n";
          print $ofh "\\addlegendentry{$file} \n";
	}


    print $ofh "\\end{axis} \n";

print $ofh "\\end{tikzpicture} \n";
print $ofh " \n";
print $ofh "\\end{document} \n";

print STDERR "Output written in $outfile\n";

system("cd $id ; cp ~/do.tikz.sh $PWD/$id ; $PWD/$id/do.tikz.sh $id");

chmod 0777, $outfile ;
sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}
