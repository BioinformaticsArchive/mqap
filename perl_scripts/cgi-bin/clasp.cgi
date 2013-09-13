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

my $SRC = $ENV{SRC} or die ;
my $ANNDIR = $ENV{ANNDIR} or die ;
my $PDBDIR = $ENV{PDBDIR} or die ;
my $APBSDIR = $ENV{APBSDIR} or die ;


$|=1;
my $verbose = 0 ; 
my (%querys) = cgi_GetTableWithPDBid();

my $q = new CGI;

print $q->header();

my $default = "";
if ($q->param()) {
	my $search = $q->param('SearchRef');
    my (%ulta) = cgi_GetTableUlta();
	my @pdbs ; 
	foreach my $key (keys %ulta){
		if($key =~ /$search/i){
		 push @pdbs, $ulta{$key} ; 	
		}
	}
	$default = join " ", @pdbs ;
	print "Ok here $search\n" if($verbose);
	print "$search = $default\n" if($verbose);
}

cgi_Start($q,"Predict functions");
output_form($q,$default,"processmain.cgi");
cgi_End($q);

cgi_Start($q,"Search functions");
cgi_FormSearch($q,"SearchRef","clasp.cgi","Search for functions that can be queried");
cgi_End($q);

sub output_form {
        my ($q,$default,$program) = @_;
        print $q->start_form(
            -name => 'main',
            -method => 'POST',
            -action => 'processmain.cgi',
        );

        print $q->start_table;
        print $q->Tr(
          $q->td('PDB Name:'),
          $q->td(
            $q->textfield(-name => "pdbname", -size => 50)
          )
        );

       print 'Browse pdb file: ',
          $q->filefield(
           -name      => 'filename',
    	  -size      => 40,
    	  -maxlength => 80);

        #print $q->Tr(
          #$q->td('Age:'),
          #$q->td(
            #$q->radio_group(
              #-name => 'age',
              #-values => [
                  #'0-12', '13-18', '18-30', '30-40', '40-50', '50-60', '60-70', '70+'
              #],
              #-rows => 4,
            #)
          #)
        #);

		my @keys = (sort values %querys);
		my $N = @keys ;
        print $q->Tr(
          $q->td('Choose function (there are ', $N, ' protein functions):'),
          $q->td(
            $q->popup_menu(
              -name => 'query',
			  -multiple=>'true',
			  -size=>8,
              -values => [sort values %querys],
              -labels => \%querys,
            )
          )
        );

        print $q->Tr(
          $q->td('or enter list of PDB ids of enzymes whose functions you want to query:'),
          $q->td(
            $q->textfield(-name => "queries", -default => $default, -size => 100, -maxlength => 10000 )
          )
        );





        #print $q->Tr(
          #$q->td('Favourite Languages:'),
          #$q->td(
            #$q->checkbox_group(
              #-name => 'language',
              #-values => ['Perl', 'C', 'C++', 'C#', 'Java', 'VB', 'Python', 'Delphi'],
              #-defaults => ['Perl'],
              #-columns => 2,
            #)
          #)
        #);
        print $q->Tr(
          $q->td($q->submit(-value => 'Submit')),
          $q->td('&nbsp;')
        );



        print $q->end_table;
        print $q->end_form;
}

