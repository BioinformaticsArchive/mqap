#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw( /home/sandeepc/Bio/Code/perl_scripts/perl_scripts/);
use MyCGI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use ConfigPDB;
use MyGeom;
use PDB;
use Proc::Daemon;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
use POSIX qw(setsid);
use POSIX qw(:sys_wait_h);

my ($SRC, $ANNDIR , $PDBDIR , $APBSDIR ) = cgi_GetEnv();

$|=1;
my $verbose = 0 ; 

my $q = new CGI;

print $q->header();

cgi_Start($q,"Predict functions");

if ($q->param()) {
        # Parameters are defined, therefore the form has been submitted
        my ($pdbname,$UC,$userquery,$pdbexists,$apbsexists) = display_results($q);
		   if($apbsexists){
		       print $q->h2("Electrostatics has been run for $pdbname");
		   }
		   else{
		       print $q->h2("Electrostatics not found for $pdbname");
               print $q->Tr(
                 $q->td('Run electrostatics?'),
                 $q->td(
                   $q->radio_group(
                     -name => 'Decision',
                     -values => [
                         'Y', 'N'
                     ],
                     -rows => 4,
                   )
                 )
               );

		   }

		   exit(0) ;
} 

cgi_End($q);

sub display_results {
        my ($q) = @_;

		my ($pdbexists, $apbsexists) = (0,0);
        my $pdbname = ($q->param('pdbname'));
        my $UC = uc($pdbname);

		$pdbexists = 1 if( -e "$PDBDIR/$UC.pdb"); 
		$apbsexists = 1 if( -e "$APBSDIR/$UC"); 


        my $savednam = cgi_SaveFile($q);
		if(!$pdbexists && !defined $savednam){
		   cgi_PrintError("pdbdir = $PDBDIR $pdbexists $UC");
		   cgi_PrintError("Specified id ($pdbname) is not a PDB id, and you have not specified a pdb file.") ;
		}


        my (%querytable) = cgi_GetTableWithPDBid();
        my (%ulta) = cgi_GetTableUlta();
        my @userquery = $q->param('query');
        my $searchquery = $q->param('queries');
        my @searchquery = split " ",$searchquery;
		if(!@userquery && !@searchquery){
		    cgi_PrintError("Need to specify at least one query protein")  ;
		}

		foreach my $l (@searchquery){
			my $uc = uc($l);
			my $nm = $querytable{$uc} ;
			push @userquery, $nm ;
		}
		@userquery = util_uniq2(\@userquery);


		my $chosenstr = join ",", @userquery ;
		my $chosen = " ";
		foreach my $query (@userquery){
			#my $nm = $querytable{$query} ;
			my $nm = $ulta{$query} ;
			cgi_PrintError("$query not defined") if(! defined $nm);
			$chosen = $chosen . "$query (" . $nm . "), " ; 
		}

		my $function = $querytable{$UC};
        print $q->p("Will check the protein $function for the following functions");
        print $q->Tr(
          $q->td(''),
          $q->td(
            $q->popup_menu(
              -name => 'query',
			  -multiple=>'true',
			  -size=>8,
              -values => \@userquery,
            )
          )
        );

		my @pdbs ; 
		foreach my $l (@userquery){
			my $uu = $ulta{$l}; 
		    push @pdbs , $uu ;
			print "$uu ,,\n" if($verbose);
		}


        return ($pdbname,$UC,\@pdbs,$pdbexists,$apbsexists) ;
}

