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
	use Proc::Daemon;
    use Getopt::Long;

	use Time::HiRes qw( usleep ualarm gettimeofday tv_interval clock_gettime clock_getres  clock);
	use POSIX qw(floor);
	use POSIX qw(setsid);

	use POSIX qw(:sys_wait_h);
	my $pid ; 
    GetOptions( "pid=i"=>\$pid);
	my $daemon = Proc::Daemon->new();

	$| = 1; 
	my $status = $daemon->Status($pid);
	my $cnt = 1000 ; 
	while($status){
	   print "pid - $pid $status .......... \n";
	   sleep(1);
	}


