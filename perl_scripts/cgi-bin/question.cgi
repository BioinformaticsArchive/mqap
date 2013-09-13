#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw( /home/sandeepc/Bio/Code/perl_scripts/perl_scripts/);
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
use MyCGI;
use Proc::Daemon;

use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
use POSIX qw(floor);
use POSIX qw(setsid);
use POSIX qw(:sys_wait_h);


$|=1;
my $verbose = 0 ; 

my $q = new CGI;

print $q->header();

    # Output stylesheet, heading etc
    #output_top($q);

    #output_top1($q);
        #output_search($q);
    #output_end1($q);


	my $SRC = $ENV{SRC} or die ;
	my $ANNDIR = $ENV{ANNDIR} or die ;
	my $PDBDIR = $ENV{PDBDIR} or die ;
	my $APBSDIR = $ENV{APBSDIR} or die ;

    if ($q->param()) {
        # Parameters are defined, therefore the form has been submitted
        my ($pdbname,$UC,$userquery,$pdbexists,$apbsexists) = display_results($q);
		my ($daemon,$Kid_1_PID,$pid);
		$SIG{CHLD} = "IGNORE" ;
		if ($pid = fork) {
			print $q->p("Started program");
			 my $start = time;
			 #while (1) {
			    print $q->p("waiting");
			    STDOUT->autoflush(1);
			    STDERR->autoflush(1);
			    print $q->p("waiting over");
			    sleep(2);
			#}
		}
		else{
		   setsid() or die "Can't start a new session: $!";
		   print $q->p("Started program\n");
		   my $rundir = "/tmp/rundir";
		   my $log = "$rundir/out.log";
		   `mkdir -p $rundir ` ;
		   `cp -r $ANNDIR $rundir` ;
   
   
		   my @l = ();
		   push @l , $UC ;
		   util_writelist2file("$rundir/list.A",$userquery);
		   util_writelist2file("$rundir/list.B",\@l);
   
		   chdir($rundir);
		   if($apbsexists){
		       print $q->p("Electrostatics has been run for $pdbname");
		   }
		   else{
		       PrintLogForCommand($q,"cd $rundir; $SRC/APBS//apbs.csh list.B ");
		   }

		   my $command = "$SRC/CSA//runRefExtractEasilyNamed.csh list.A list.B";
		   $daemon = Proc::Daemon->new(    work_dir     => $rundir, child_STDOUT => $log, child_STDERR => '+>>debug.txt', pid_file     => 'pid.txt', exec_command => $command,);
	       $Kid_1_PID = $daemon->Init;
		   print $q->p("Running CLASP - pid = $Kid_1_PID");

	   #PrintLogForCommand($q,"/usr/lib/cgi-bin/waitforDaemon.cgi -pid $Kid_1_PID");



		   #PrintLogForCommand($q,"cd $rundir; $command");
		   exit(0) ;
		}
		print $q->p("waiting over at the end");
    } else {
        # We're here for the first time, display the form
        output_form($q);
    }

    # Output footer and end html
    output_end($q);

    exit 0;

    #-------------------------------------------------------------


    # Outputs a footer line and end html tags

    # Displays the results of the form
sub display_results {
        my ($q) = @_;

		my ($pdbexists, $apbsexists) = (0,0);
        my $pdbname = ($q->param('pdbname'));
        my $UC = uc($q->param('pdbname'));
		$pdbexists = 1 if( -e "$PDBDIR/$UC.pdb"); 
		$apbsexists = 1 if( -e "$APBSDIR/$UC"); 

        my $savednam = save_file($q);
		if(!$pdbexists && !defined $savednam){
		   PrintError("Specified id ($pdbname) is not a PDB id, and you have not specified a pdb file.") ;
		}


        # my $howmany = $q->param('age');
        my %querytable = GetTable();
        my @userquery = $q->param('query');
		PrintError("Need to specify at least one query protein (or ALL)") if(!@userquery) ;
		my $chosenstr = join ",", @userquery ;
		my $chosen = " ";
		foreach my $query (@userquery){
			my $nm = $querytable{$query} or die;
			$chosen = $chosen . "$query (" . $nm . "), " ; 
			
		}
        #my @favourite_languages = sort $q->param('language');

        print $q->h4("Hi $pdbname");
        #print $q->p("You have chosen pdb $userquery which has function $querytable{$userquery}, and you are $howmany years old.");
        print $q->p("Will check the protein $pdbname for the following PDB ids: $chosen.");
        #print $q->p("Your favourite languages are:");

        #print $q->table(
            #{-border => 1, -cellpadding => 3},
            #$q->Tr($q->td(\@favourite_languages)),
        #);

        return ($pdbname,$UC,\@userquery,$pdbexists,$apbsexists) ;
}

    # Outputs a web form
sub output_form {
        my ($q) = @_;
        print $q->start_form(
            -name => 'main',
            -method => 'POST',
            -action => 'question.cgi',
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

        my %querys = GetTable();
		my @keys = (sort keys %querys);
		my $N = @keys ;
        print $q->Tr(
          $q->td('Choose query PDB (there are ', $N, ' protein functions):'),
          $q->td(
            $q->popup_menu(
              -name => 'query',
			  -multiple=>'true',
			  -size=>8,
              -values => [sort keys %querys],
              -labels => \%querys,
            )
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

