
package MyUtils;
use Carp ;
use POSIX ;
require Exporter;
use Algorithm::Combinatorics qw(combinations) ;
use Math::NumberCruncher;
use Math::MatrixReal;  # Not required for pure vector math as above
use Math::Geometry ; 
use Math::VectorReal qw(:all);  # Include O X Y Z axis constant vectors
#use Math::Trig;
#use Math::Trig ':radial';
no warnings 'redefine';
my $EPSILON = 0.01;

  local $SIG{__WARN__} = sub {};

@ISA = qw(Exporter);
@EXPORT = qw( util_execute_chop util_exit_if_doesnt_exist util_get_tag util_print_n_log util_get_user 
            util_get_cmdline util_num_lines util_percentage util_percentages util_printAndDo util_get_pwd util_log_base util_check_machine
	    util_get_tech util_printAndWrite2Script 
        util_get_time_from_string util_isDesignSuccessful util_parseTimelog util_diff util_round
        util_print_mgc_home util_get_mgc_home util_write_list_in_file util_fullline 
		util_ceil util_floor
		util_IsPro
        util_verilog2eqn util_runSis util_two2thepowerof util_assign_list2list util_emitGrid
        util_wait_on_lockfiles util_writePsp util_get_grid_cmd util_print_synp_file
		util_writelist2file
		util_readAPBSPotentialFromStart
		util_sortsingleString
		util_readfasta
		util_ReadAnnotateFile util_ReadAnnotateFileFRAGAL
		vprint vprintheader vSetVerbose vIncrVerbose vDecrVerbose
        util_copy_table
		util_GetClosestAtoms_intwoPDBs
		util_Ann2Simple
		util_GetMeanSD
util_AreResiduesContinuous
util_FindRmsd
util_FindRmsdAllAtoms
util_ProcessSingleLine

util_ParseAAGroups
util_GetPotForAtom
util_GetPotDiffForAtoms
util_GetPotDiffForResidues
util_ReadPdbs
util_WriteClustalAln
		util_WriteFastaFromAtoms
		util_WriteFastaFromResidueNumbers
		
        util_print_vars util_uniq2
        util_SAVEDIR util_INITNAMES
        util_read util_append util_write util_pick_random_from_list
		util_make_list util_make_table
		util_wget util_get_pdb 
		util_makeCSH
		util_parse_pdbseqres
		util_readPDB
		util_read_list_words
		util_read_list_sentences
		util_enter_maxcutoff
        util_is_integer util_is_float util_EnterName util_EnterNumber util_EnterTwoNumbers util_EnterTwoNames 
		util_AddBeforeEach
		util_ignoreIfDistanceIsLessthan util_ignoreIfAnyAreEqual util_ignoreIfAnyAreFurtherThanCutoff
		util_split_list_numbers
		util_read_Mapping_PDB_2_SWISSPROT util_filter_basedon_EC util_getPDBID_basedon_SP util_getECfromPDB
		util_ReadLine
		util_ParseBlocks util_ParseBlockForString
		util_ProcessRowAndColumnsForMean
		util_SetEnvVars
		util_format_float
		util_mysubstrDontStripSpace util_mysubstr
		util_printResult
		util_printTablePre util_printTablePost util_printTableLine util_PrintMeanAndSD
		util_Annotate util_ReadAnnfile
		util_table_print
		util_pick_n_random_from_list
		util_ExtractSliceFromFasta
		util_GetFastaFiles 
		util_maketablefromfile 

		util_readAPBSPotential
		util_usage util_CmdLine
		util_parsePDBSEQRES
		util_SortTwoStrings
		util_GetEnv
		util_IsZero
		util_Banner util_PrintInfo

		util_getTmpFile
		util_PrintOutConf

ParseAPBSResult
		util_printHtmlHeader util_printHtmlEnd util_HtmlizeLine
		util_HtmlTableHead util_HtmlTableEnd util_HtmlTableCell
		util_MakeLink
		util_EC_CreateLevels util_EC_AddPDB util_EC_CorrelatePDBS
util_readPeptideInfo
util_getECID
	    );

use strict ;
use FileHandle ;
use Getopt::Long;


my $verbose = 0 ;
my $havetokeepthispostive = 13 ;

sub util_readPDB{
    my ($pdb1) = @_ ;
	my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC,$MATCH3D,$ANNDIR, $UNIPROT) = util_SetEnvVars();
    my $origpdb = $pdb1 ;
    $pdb1 = "$PDBDIR/$pdb1.pdb";

    my $pdb = new PDB();
    #$pdb->SetLogFile($ofh);
    $pdb->ReadPDB($pdb1);
    return $pdb ;
}

sub util_SetEnvVars{
   my @vars = qw ( RESULTDIR PDBDIR FASTADIR APBSDIR FPOCKET SRC MATCH3D ANNDIR UNIPROT );
   my @ret ;
   print STDERR "=============\n" if($verbose);
   foreach my $var (@vars){
       my $v  = $ENV{$var} or die "$var not set";
       #print  STDERR " $var = $v\n " ;
	   push @ret, $v ;
   }
   print STDERR  "\n===============\n" if($verbose);
   return @ret ;
}


sub util_GetEnv{
	my ($l) = @_ ;
    my $ret = $ENV{$l} or die "Need to set environment variable $l"; 
	return $ret ;
}

sub util_make_list{
	my (@l) = @_ ;
	return \@l ;
}
sub util_make_table{
	my ($l) = @_ ;
	my $t = {};
	map {$t->{$_} = 1 ;} @{$l} ;
	return $t ;
}


sub util_wait_on_lockfiles{
    my ($ofh,$lockfiles) = @_ ;
    my @lockfiles = @{$lockfiles};
    print $ofh "echo Waiting for lock files to disappear\n";
    print $ofh "while(1) \n";
    print $ofh "sleep 5\n";
    my $str = "";
    map { $str.= " -e $_ || " ; } (@lockfiles);
    $str .= " -e $lockfiles[0]" ;
    print $ofh "if( $str)  then \n";
    print $ofh "else \n";
    print $ofh "break \n";
    print $ofh "endif \n";
    print $ofh "end \n";
}

sub util_assign_list2list{
     my ($list1,$list2,$assignment) = @_ ;
     my @list1 = @{$list1};
     my @list2 = @{$list2};
     map { $assignment->{$_} = [] if(!defined $assignment->{$_}) ; } @list1;
     my $num = @list1 ;
     my $cnt = 0 ;
     foreach my $l2 (@list2){
         my $l1 = $list1[$cnt];
         push @{$assignment->{$l1}} , $l2;
         $cnt++;
         $cnt = 0 if($cnt == $num);
     }
     #return $assignment;
}


sub util_two2thepowerof{
     my ($number) = @_;
     my $ret = 1; 
     foreach my $i (1..$number){
        $ret = 2*$ret;
     }
    return $ret ;
}


sub util_fullline{
    my ($fh,$firstline,$delim) = @_ ;
    if($firstline =~ /\s*$delim\s*$/){
        return ($firstline);
    }
    my $retline = $firstline ;
    while(<$fh>){
         chop ;
         $retline .= $_;
         if(/\s*$delim\s*$/){
             return ($retline);
         }
    }
    undef ;
}


sub util_print_vars{
     my ($dirname,$ofph) = @_ ;
     my @envs = qw(PERLLIB );
     map { print $ofph  "#$_ = $ENV{$_}\n"; } @envs ;
}


sub util_write_list_in_file{
     my ($filenm) = shift @_ ;
     my (@list) = @_ ;
     unlink $filenm ;
     my $fh = new FileHandle($filenm,O_CREAT|O_WRONLY) or croak " $! $filenm" ;
     map { print $fh "$_\n"; } @list ;
}

sub util_round {
    my($number) = shift;
    return int($number + .5);
}

sub util_get_pwd{
   my $PWD = getcwd ;
   return $PWD ;
}


sub util_execute_chop{
  my ($exec,$fname) = @_;
  my  $ret = ` $exec $fname `;
  chop $ret ;
  $ret ;
}
sub util_printAndDo{
   my ($what,$dry) = @_ ;
   my $comment = defined $dry ? " Will run ( this is dry run ) " : "Running" ;
   print STDERR "$comment $what ...\n";
   system($what) if(!defined $dry);
}
sub util_printAndWrite2Script{
   my ($what,$fh) = @_ ;
   ## 
   #$what =~ s/\"/\\\"/g ;
   croak " undefined file handle " if(!defined $fh);
   print STDERR "Running $what ...\n";
   print $fh "$what ; ";
}


sub util_exit_if_doesnt_exist{
  my ($fname) = @_;
  croak "File $fname does not exist. Quitting " if(!-e $fname);
}

sub util_get_tag{
  return "" if(!-e "CVS/Tag");
  my $fh = new FileHandle("CVS/Tag",O_RDONLY) or croak ;
  my $tag = <$fh>;
  $tag =~ s/^T//;
  $tag ;
}

sub util_print_n_log {
    my ($ofh,$msg) = @_ ;
	print $msg ;
	print $ofh $msg ;
}

sub util_get_user{
   my $user = `whoami` ;
   chop $user ;
   $user ;
}
sub util_get_cmdline{
    my ($exec , $list ) = @_ ;
	map { $exec = $exec . " $_ " ; } @$list ;
	$exec ;

}
sub util_num_lines{
  my ($file) = @_ ;
  return 0  if(!-e  $file);
  my $fh = new FileHandle($file,O_RDONLY) or croak ;
  my $num = 0 ; 
  while(<$fh>){ $num++ ; }
  $num ;
}

sub util_percentage{
   my ($a,$b,$justval) = @_ ;  
   croak "a is undefined" if(!defined $a);
   croak "b is undefined" if(!defined $b);
   return $a if(defined $justval);
   $a = 1 if($a eq 0 || !defined $a);
   $b = 1 if($b eq 0 || !defined $b);
   my $percent = ($a - $b)/$a ;  # Changing the diff so that we are in sync with harness eqn
   #my $percent = 1 - ($a/$b);
   #my $percent = ($a/$b)-1 ; 
   #int($percent*100) . "%" ;
   int($percent*100);
}

sub util_diff{
   my ($a,$b,$justval) = @_ ;  
   return $a if(defined $justval);
   $a = 1 if($a eq 0 || !defined $a);
   $b = 1 if($b eq 0 || !defined $b);
   my $percent = ($a - $b); 
}

sub util_log_base {
    my ($base, $value) = @_;
    if($value < $base){
        return 1;
    }
     my $val =  log($value)/log($base);
     my $finalval =ceil($val);
     return $finalval;
}

sub util_ceil{
    my ($value) = @_;
     my $finalval =ceil($value);
	 return $finalval;
}
sub util_floor{
    my ($value) = @_;
     my $finalval =floor($value);
	 return $finalval;
}

sub util_read_list_numbers{
    my @list = ();
    my ($file) = @_ ;
    my $fp = new FileHandle($file,O_RDONLY) or croak " Error for file: $file $!" ;
    while(<$fp>){
         next if(/^\s*$/);
		 s/\s*//g;
         chomp ;
         croak " just expect a number " if(!/^[+-]?\d+(\.\d+)?$/);
         my ($num) = $_ ;
         push @list, $num ;
    }
    return @list ;
}

sub util_maketablefromfile{
    my ($file) = @_ ;
    my $fp = util_read($file);
	my $table ;
    while(<$fp>){
         next if(/^\s*$/);
         next if(/^\s*#/);
         my ($a,$b) = split ; 
         $table->{$a}= $b ;
    }
    return $table ;

}


sub util_read_list_words{
    my @list = ();
    my ($file) = @_ ;
    my $fp = new FileHandle($file,O_RDONLY) or croak " $!" ;
    while(<$fp>){
         next if(/^\s*$/);
         next if(/^\s*#/);
         chop ;
         my @l = split ; 
         push @list, @l ;
    }
    return @list ;

}
sub util_read_list_sentences{
    my @list = ();
    my ($file) = @_ ;
	my $PWD = getcwd ;
    my $fp = new FileHandle($file,O_RDONLY) or croak " util_read_list_sentences :  $! $file $PWD" ;
    while(<$fp>){
         next if(/^\s*$/);
         chop ;
         push @list, $_ ;
    }
    return @list ;

}
sub util_get_abs_path{
    my ($fname) = @_ ; 
    my $pwd = util_get_pwd();
    return $fname if($fname =~ /^\s*\// || $fname =~ /^\s*\~/);
    my $abspath = $pwd . "/" . $fname ;
    return $abspath ;
}



sub util_get_time_from_string{
 my ($str) = @_ ;

 my ($a,$b,$c,$d) = ($str =~ /(\d+)\.(\d+)u\s*(\d+)\.(\d+)s/);
 return $a + $c ;

}

sub util_isDesignSuccessful{
    my ($logname) = @_ ;
    my $fp = new FileHandle($logname,O_RDONLY) or croak " $! $logname" ;
    my $foundSynthesized = "FAILED";
    while(<$fp>){
        if(/Finished synthesizing design/){
            $foundSynthesized = "PASSED";
        }
    }
    return $foundSynthesized;
}

sub util_parseTimelog {
   my ($logname) = @_ ;
   my $fp = new FileHandle($logname,O_RDONLY) or croak " $logname $!" ;
   my $lastline;
   while(<$fp>){
     $lastline = $_;
   }
   return util_get_time_from_string($lastline);
}

sub util_append{
     my ($outfile)= @_;
	 die "Blank file name " if($outfile =~ /^\s*$/);
     #unlink $outfile;
     my $fh = new FileHandle($outfile,O_WRONLY|O_APPEND) or croak " could not write file $outfile as $!" ;
     return $fh ;
}

sub util_write{
     my ($outfile)= @_;
     unlink $outfile;
     my $fh = new FileHandle($outfile,O_CREAT|O_WRONLY) or croak " could not write file $outfile as $!" ;
     return $fh ;
}

sub util_writelist2file{
     my ($outfile,$list)= @_;
     unlink $outfile;
     my $fh = new FileHandle($outfile,O_CREAT|O_WRONLY) or croak " could not write file $outfile as $!" ;
	 foreach my $x (@{$list}){
	 	print $fh "$x\n";
	 }
     return $fh ;
}

sub util_read{
     my ($outfile)= @_;
     my $fh = new FileHandle($outfile,O_RDONLY) or croak " could not read file $outfile as $!";
     return $fh ;
}

sub util_wget{
     my ($file)= @_;
     util_printAndDo("wget --no-proxy $file");
}

sub util_makeCSH{
     my ($ofh)= @_;
     print $ofh "#!/bin/csh -f\n";
}

sub util_get_pdb{
     my ($dir,$file)= @_;
	 my $fname = $dir . "/" . $file . ".pdb" ;
	 if(-e $fname){
	 }
	 else{
	 	util_wget($fname); 
	 }
	 return $fname ; 
}
                                                                                                                                                             
sub util_pick_random_from_list{
    my ($list) = @_ ;
    my @temporaries = @{$list};
    my $num = @temporaries ;
    my $r = floor($num*rand());      
    my $operator = $temporaries[$r] or croak ;
    return $operator ;
}

sub util_pick_n_random_from_list{
    my ($list,$n) = @_ ;
	my @l ; 
	my $done ; 
	while($n){
		my $x = util_pick_random_from_list($list);
		if(! exists $done->{$x}){
		    push @l, $x ; 
			$done->{$x} = 1 ; 
			$n--;
		}
	}
	return \@l ; 
}




sub util_enter_maxcutoff{
	print STDERR " Enter max cutoff number \n";
	my $qnum = <> ;
	chop $qnum ; 

	my $ret = 1000000 ;
	$ret = $qnum if($qnum !~ /^\s*$/);
	return $ret ;
}
sub util_is_integer {
   defined $_[0] && $_[0] =~ /^[+-]?\d+$/;
}

sub util_is_float {
      defined $_[0] && $_[0] =~ /^[+-]?\d+(\.\d+)?$/;
}

sub util_EnterName{
	my ($default) = @_ ; 
	if(defined $default){
		print "Press enter to choose default name $default\n";
	}
	my $qname = <> ;
	chomp $qname ; 
	if(defined $default){
		if($qname =~ /^\s*$/){
			return $default ; 
		}
	}
	my @l = split " ",$qname; 
	if(@l != 1){
		print "Warning: Need a single name. Try again\n";
		return util_EnterName(); 
	}
	return $l[0]; 
}

sub util_EnterNumber{
	my $qnum = <> ;
	chomp $qnum ; 
	my @l = split " ",$qnum; 
	if(@l != 1 || !util_is_integer($l[0])){
		print "Warning: Need a single number. Try again\n";
		return util_EnterNumber(); 
	}

	return $l[0]; 
}
sub util_EnterTwoNumbers{
	my $qnum = <> ;
	chomp $qnum ; 
	my @l = split " ",$qnum; 
	if(@l != 2 || !util_is_integer($l[0]) || !util_is_integer($l[1])){
		print "Warning: Need 2 numbers. Try again\n";
		return util_EnterTwoNumbers(); 
	}

	return @l ;
}
sub util_EnterTwoNames{
	my $qname = <> ;
	chomp $qname ; 
	my @l = split " ",$qname; 
	if(@l != 2){
		print "Warning: Need 2 Names. Try again\n";
		return util_EnterTwoNames(); 
	}

	return @l ;
}


sub util_AddBeforeEach{
	my ($expr,@l) = @_ ; 
	my $str  = join " -$expr ",@l ;
	$str  = " -$expr $str";
	return $str ; 
}

sub util_ignoreIfDistanceIsLessthan{
	my ($num,@l) = @_ ; 
    my $iter = combinations(\@l, 2);
    while (my $c = $iter->next) {
        my @combo = @{$c} ; 
	    if(abs($combo[0] - $combo[1]) < $num){
			return 1 ; 
		}
	}
	return 0 ;
}
sub util_ignoreIfAnyAreEqual{
	my (@l) = @_ ; 
    my $iter = combinations(\@l, 2);
    while (my $c = $iter->next) {
        my @combo = @{$c} ; 
	    if($combo[0] == $combo[1]){
			return 1 ; 
		}
	}
	return 0 ;
}

sub util_split_list_numbers{
	my ($l,$point) = @_ ; 
	my @l = @{$l} ; 

	my @lte ;
	my @gt ;
	foreach my $e (@l){
		if($e <= $point){
			push @lte, $point ;  
		}
		else{
			push @gt, $point ;  
		}
	}
	my $n1 = @lte ;
	my $n2 = @gt ;
	return (\@lte, \@gt,$n1,$n2);
}


sub util_read_Mapping_PDB_2_SWISSPROT{
	my ($infile) = @_;
    my $info = {};
    my $ifh = util_read($infile);

    #ignore first two lines
    <$ifh>;
    <$ifh>;
	my $uniqueEC ; 
	my $uniqueSP ; 
    while(<$ifh>){
         next if(/^\s*$/);
	     s/|//g;
	     s/,//g;
	     s/,//g;
	     my ($nm,$j1,$chainid,$j2,$n1,$j3,$n2,$j4,$swissprot,$jjj,$ec) = split ;
		 #print " $swissprot $ec\n";
    
		     if($chainid eq "A"){
	            if(!defined $info->{$nm}){
		           $info->{$nm} = {} ;
	           }
	  	         #print "$nm $chainid $swissprot  \n";
	             $info->{$nm}->{SWISSPROT} = $swissprot ;
	             $info->{$nm}->{EC} = [] if(!defined $info->{$nm}->{EC});
	             $info->{SWISSPROT2EC}->{$swissprot} = [] if(!defined $info->{SWISSPROT2EC}->{$swissprot}) ;
	             if($ec ne "0.0.0.0"){
	                push @{$info->{$nm}->{EC}}, $ec ; 
					push @{$info->{SWISSPROT2EC}->{$swissprot}},$ec ;
				    $uniqueSP->{$swissprot} = 1 ; 
				    $uniqueEC->{$ec} = 1 ; 
				 }
			}
    }
    close($ifh);
	return ($info,$uniqueEC,$uniqueSP) ; 
}

sub util_getECfromPDB{
	my($info,$nm) = @_ ; 
    $nm = lc($nm);
	my $ec =  $info->{$nm}->{EC} ; 
    return undef if(!defined $ec);
	return $ec ; 
}


sub util_filter_basedon_EC{
	my ($info,$uniqueEC,$uniqueSP,$list,$ofh,$ignore0000) = @_ ; 
	my @list = @{$list};
    my $N = @list  ;
    my $ecdone = {};
    my $spdone = {};
    my $pdbTable = {};
    my $cnt = 0 ;
    my $ignored = util_write("ignored");
    foreach my $UCPDBID  (@list){

       my $pdbid = lc($UCPDBID);
	   if(!defined $info->{$pdbid}){
	   	  print $ignored "PDB $pdbid not found in mapping \n";
		  next ;
	   }
       my @ec = @{$info->{$pdbid}->{EC}};
	   my $sp = $info->{$pdbid}->{SWISSPROT};
	   my $N = @ec ; 
	   if($N > 1){
	   	  print $ignored "PDB $pdbid ignored as it has more than 1 :$N ECS\n";
		  next ;
	   }
	   if(@ec == 0){
	        my @ECCC = @{$info->{SWISSPROT2EC}->{$sp}}; 
			if(@ECCC == 0){
				print $ignored "Ignoring pdb $pdbid with swiss $sp as there are no ECS\n";
				next ; 
			}
	   		print "Did not find EC number for $pdbid\n";
			@ec = @ECCC ;
       }
   	   print $ofh "$UCPDBID\n" if(defined $ofh);
	   $spdone->{$sp} = $pdbid ; 

	   my $added = 0 ; 
	   print "did not find EC for $pdbid \n" if(@ec == 0);
	   foreach my $ec (@ec){
	   		  #if(exists $ecdone->{$ec}){
			  	  #print $ignored "$ec exists already for $pdbid $ecdone->{$ec} \n";
				  #next ;
			  #}
			  $added = 1 ;
	          $ecdone->{$ec} = [] if(!defined $ecdone->{$ec});
	          push @{$ecdone->{$ec}}, $pdbid ; 
		}

	    $pdbTable->{$pdbid} = $sp ; 
	    $cnt++ if($added);

   }
   print "Wrote ignored PDBS in ignored\n";

   return ($ecdone,$spdone,$pdbTable,$cnt); 
}


sub util_getPDBID_basedon_SP{
	my ($info,$uniqueEC,$list,$id) = @_ ; 
    my ($ecdone,$spdone,$pdbTable,$cnt)= util_filter_basedon_EC($info,$uniqueEC,$list);
	if(exists $pdbTable->{$id}){
		return $id ; 
	}
	else{
       my $sp = $info->{$id}->{SWISSPROT};
	   if(exists $spdone->{$id}){
		   return $spdone->{$id}  ;  
	   }
	   else{
		   return undef ; 
	   }
	}
}


###########################################################################
# Parses a file and returns blocks between start and end
###########################################################################

sub util_ParseBlocks{
	my ($infile,$start,$end) = @_;
    my @blocks ;
    my $ifh = util_read($infile);

    while(<$ifh>){
         if(/$start/){
		 	my @block ;
			push @block,$_;
			while(!/$end/){
                $_ = <$ifh>;
                last if(!$_);
                if(/$start/){
                    @block = ();
                    push @block,$_;
                }
                else{
                    push @block,$_;
                }

			}
			push @blocks, \@block ;
		 }
    }
    close($ifh);
	return \@blocks ;
}

sub util_ParseBlockForString{
	my ($block,$str) = @_;
    my @lines ;
    foreach my $i (@{$block}){
		$_ = $i ;
         if(/$str/){
			push @lines,$_;
		 }
    }
	return \@lines ;
}



#############################################################
## Calculate the mean and SD of a matrix, columnwise 
## Also takes a range, and tells how many lie outside that range.
## So this range ideally makes sense for one column only
#############################################################
sub util_ProcessRowAndColumnsForMean{

   my ($rows,$top,$low)= @_ ;
   my @rows = @{$rows};
   my $nrows = @rows - 1;
   my @cols ; 


    #print "Number of rows -1 = $nrows\n";
	my $once = 1 ;
    foreach my $i (0..$nrows){
	    my $row = $rows[$i];
	    my @row = @{$row};
	    my $ncol = @row - 1 ;
        if($once){
		   print "Number of column -1 = $ncol\n";
		   $once = 0 ;
		}
        foreach my $j (0..$ncol){
		    if(!defined $cols[$j]){
			    my @l = ();
			    $cols[$j] = \@l;
		    }
		    push @{$cols[$j]}, $row[$j];
	    }
    }
    
	my @means ; 
	my @sds ; 
	my $NN = @cols ;
    foreach my $container (@cols){
        my $mean = Math::NumberCruncher::Mean($container) or warn "Mean not found" ;
        my $sd = Math::NumberCruncher::StandardDeviation($container) or warn "sd not found" ;
		next if(!defined ($mean && $sd));
		push @means, util_format_float($mean,1) ;
		push @sds, util_format_float($sd,1) ;
        my $incnt = 0 ;
        my $outcnt = 0 ;
	    foreach my $i (@{$container}){
		    $i = -($i);
		    if($i > $low && $i < $top){
			    $incnt++;
		    }
		else{
			    $outcnt++;
		    }
	    }
	    print "mean = $mean sd = $sd \n";
	    print "incnt = $incnt outcnt = $outcnt \n";
    }
	return (\@means,\@sds);

}


sub util_format_float{
	my ($d,$v) = @_; 
	if (defined $v && $v eq 3) {return sprintf("%8.3f", $d);}
	if (defined $v && $v eq 1) {return sprintf("%8.1f", $d);}

	return sprintf("%8.3f", $d); 
}

sub util_mysubstr {
	my ($len,$str,$start,$end) = @_ ; 
	if($len < $start ){
		die "dying $str" if(!($str =~ /TER/));
	    return "" ;
	}
	my $diff = $end == 1 ? $end :  $end - $start + 1 ; 
	$start-- ; 
	#print "($str,$start,$diff)\n";
	my $s =  substr($str,$start,$diff);
	$s =~ s/\s*//g ; 
	return $s ; 
}

sub util_mysubstrDontStripSpace {
	my ($len,$str,$start,$end) = @_ ; 
	if($len < $start ){
		die "dying $str" if(!($str =~ /TER/));
	    return "" ;
	}
	my $diff = $end == 1 ? $end :  $end - $start + 1 ; 
	$start-- ; 
	return substr($str,$start,$diff);
}


sub ParseAPBSResult{
   my ($size,$outfile,$infile,$listfile) = @_ ;
   my $ofh = util_write($outfile);
   my $ifh = util_read($infile);
   my $list = {};
   if(defined $listfile){
       my @list= util_read_list_sentences($listfile);
       map { $list->{$_} = 1 ; } @list ;
   }
   

   print "Parsing apbs potentials in $infile, output in $outfile .............\n";
   my $blocks = util_ParseBlocks($infile,"Starting read","Ending read");
   my @blocks = @{$blocks};

   my $len = @blocks ; 
   print $ofh "\%There were $len blocks\n";
   print STDERR "\%There were $len blocks\n";



    util_printTablePre($ofh,"caption");

    my @diffs = ();
    foreach my $block (@blocks){

	chomp $block ;
	    my $lines = util_ParseBlockForString($block,"Resultfile is");
	    if(@{$lines} == 0){
		    die ;
	    }
	    my $line = shift @{$lines}; 
	    my ($pdb)  = ($line =~ /\/(....)\.pdb.out/);
	    ($pdb)  = ($line =~ /(....)\.pdb.out/) if(!defined $pdb);
	    if(defined $listfile && defined $pdb ){
		     if(!exists $list->{$pdb}){
			    print "nexting\n";
				#return undef ;
			 	next;
			 }
	    }
    
    
	    $lines = util_ParseBlockForString($block,"potential");
	    if(@{$lines} != $size){
			print "nexting as size $size doestn match\n";
				return undef ;
		    next ;
	    }
    
	    print $ofh "$pdb &  " if(defined $pdb);
       my @vals  ; 
       my $somethingwrong = 0 ; 
       while($line = shift @{$lines}){
		    my ($val) = ($line =~ /potential\s*=\s*(.*)/);
		    if(!defined $val || $val =~ /^\s*$/){
			    $somethingwrong = 1 ;
			    last ; 
		    }
		    #print $ofh "$val ";
		    push @vals, $val;
	    }
    
	    next if($somethingwrong);
    
    
        my $iter = combinations(\@vals, 2);
        my @diff  ;
        while (my $c = $iter->next) {
                my @combo = @{$c} ; 
			    my ($a,$b) = @combo ; 
			    my $d= $a - $b ;
			    #print " $d= $a - $b ; \n";
			    $d=util_format_float($d,1);
			    push @diff , $d; 
	    }
	    util_printTableLine($ofh,\@diff);
	    push @diffs , \@diff ;
    }
    
    #my ($means,$sds) = util_ProcessRowAndColumnsForMean(\@diffs,250,150);
	#util_PrintMeanAndSD($ofh,$means,$sds);


    util_printTablePost($ofh,"label");


    return \@diffs ;
}

sub util_PrintMeanAndSD{
	my ($ofh,$means,$sds) = @_ ;
    #print $ofh "\\rowcolor{orange} \n";
	print $ofh "Mean & " ;
	util_printTableLine($ofh,$means);
    #print $ofh "\\rowcolor{orange} \n";
	print $ofh "SD & ";
	util_printTableLine($ofh,$sds);
}


sub util_printResult{
    my ($ofh,$bestScore,$bestList,$cnt) = @_ ; 
	carp "Best score not defined" if(! defined $bestScore);
	print $ofh  "#RESULT $cnt  SCORE - $bestScore\n";
	print  $ofh "# ";
    foreach my $atom (@{$bestList}){
          my ($res,$num,$type) = split "/", $atom ;
	      print $ofh  "-  $atom ";
    }
	print  $ofh "\n";
}


sub util_printTablePre{
    my ($ofh,$caption) = @_ ; 
	$caption = "XXX" if(!defined $caption);
    print $ofh "\\begin{center} \n";
    print $ofh "\\begin{table*} \n";
   print $ofh "\\caption { $caption }  \n";
    #print $ofh "\\rowcolors{1}{tableShade}{white} \n";
    
    print $ofh "\\begin{tabular}{ l l l l l l l l l l l l l l l l  l l  l l l l l l } \n";
	#print $ofh "\\rowcolor{red!50}  \n";
}

sub util_printTablePost{
    my ($ofh,$caption) = @_ ; 
	$caption = "XXX" if(!defined $caption);

   #print $ofh "\\rowcolor{green!50}  \n";
   #print $ofh "\\rowcolor{orange!50}  \n";
   print $ofh "\\end{tabular}  \\label{label} \n";
   #print $ofh "\\caption {\\bf $caption }  \n";
   print $ofh "\\end{table*} \n";
   print $ofh "\\end{center} \n";
}

sub util_printTableLine{
	my ($ofh,$list) = @_ ; 
	my @l ; 
	map { 
	   if(util_is_float($_)){
	   	  $_ = util_format_float($_,1);
	   }
	   push @l, $_ ; 
    } @{$list} ;

	my $str = join " & ", @l;
	print $ofh " $str \\\\ \n";
	#print $ofh "\\hline \n";
}

sub util_readAPBSPotentialFromStart{
	my ($protein,$apbsdir) = @_ ; 
    my $pqrfile = "$apbsdir/$protein/$protein.pqr";
    my $pqr = new PDB();
    $pqr->ReadPDB($pqrfile);
    my @pots = ();
    my $potential = "$apbsdir/$protein/pot1.dx.atompot";
    util_readAPBSPotential(\@pots,$potential);
	return ($pqr,\@pots);
}

sub util_readAPBSPotential{
	my ($pots,$potential) = @_ ; 
    my $ifh = util_read($potential);
	print "util_readAPBSPotential : Reading file $potential \n";
    while(<$ifh>){
         next if(/^\s*$/);
	     chop ;
	     my @l = split ",",$_;
	     #print "$l[3] \n";
	     push @{$pots}, $l[3] ;
    }
	close($ifh);
	
}

sub util_CmdLine{
    my ($nm,$var) = @_ ;
	#$var = ${$nm} ;
    die "Error: In command line parsing. Needed command line ==> $nm" if(!defined $var);
}


sub util_parsePDBSEQRES{
	my ($infile,$all) = @_ ; 
    my $ifh = util_read($infile);

	my $seenNm ; 
	my $info ; 
    while(<$ifh>){
         next if(/^\s*$/);
	     if(/^\s*>/){
	        my ($nm,$type,$len,$fullnm) = parseSingleLinePDBSEQRES($_);
			next if(!defined $nm); 
			next if(exists $seenNm->{$nm}); 
			$seenNm->{$nm} = 1 ;

	        my $seq = <$ifh> ;
		    chomp $seq ; 

			## just process proteins unless all is specified
			if($all){
			     next if($type !~ /protein/i);
			}


		    $info->{$nm} = {};
		    $info->{$nm}->{TYPE} = $type ;
		    $info->{$nm}->{LEN} = $len ;
		    $info->{$nm}->{FULLNM} = $fullnm ;
		    $info->{$nm}->{SEQ} = $seq ;
		    $info->{$nm}->{NM} = $nm ;
	 	}
	 }

	 return $info ;
}
  



sub parseSingleLinePDBSEQRES{
	my ($line) = @_ ; 
	my ($nm,$type,$len,$fullnm) = ($line =~ /.(....).*mol:(\w+)\s*length:(\d+)\s*(.*)/);
	return ($nm,$type,$len,$fullnm) ;

}
sub util_Annotate{
	my ($file) = @_ ; 
	my ($outfile) = "$file". ".annotate";
	util_printAndDo("annotate.pl -in ~/pdb_seqres.txt -lis $file -out $outfile -cutoff 100 -anndis 10 ");

}

sub util_IsZero{
	my ($num) = @_ ; 
	if(abs($num) < $EPSILON){
		return 1 ; 
	}
	else{
		return 0 ; 
	}

}

sub util_Banner{
	my ($str) = @_ ; 
	print STDERR "===============================================\n";
	print STDERR "$str\n";
	print STDERR "===============================================\n";

}
sub util_PrintInfo{
	my ($str) = @_ ; 
	print STDERR "Info: $str\n";

}


sub util_getTmpFile{
	my $time = time ;
    my $tmpfile =  "sandeeptmp.$time";
	return $tmpfile ;
}

sub util_percentages{
	my (@values) = @_ ;
	my $sum = 0 ; 
	#print " KKKKKKKKKKKKK " , @values , "\n";
	foreach my $v (@values){
	   $sum = $sum + $v ; 
	}
	my @l ; 
	foreach my $v (@values){
	   push @l, util_format_float(($v*100)/$sum,3) ; 
	}
	return @l ;
}

sub util_printHtmlHeader{
	my ($ofh,$header1,$header2) = @_ ;
    print $ofh "<html> \n";
    print $ofh "<h1>$header1</h1> \n";
    print $ofh "<body> \n";

	if(defined $header2){
    print $ofh "<html> \n";
    print $ofh "<h2>$header2</h2> \n";
    print $ofh "<body> \n";
	}
}



sub util_printHtmlEnd{
	my ($ofh) = @_ ;
    print $ofh "</body> \n";
    print $ofh "</html> \n";
}

sub util_HtmlizeLine{
	my ($line) = @_ ;
	chomp $line ; 
	#return $line  . "<br />" ;
	return $line ;

}

sub util_HtmlTableHead{
	my ($ofh,@headers) = @_ ;
    print $ofh "<table border=\"1\" cellpadding=\"5\" cellspacing=\"5\" width=\"100%\">\n";
    print $ofh "<tr>\n";
	foreach my $h (@headers){
        print $ofh "<th>$h</th>";
	}
    print $ofh "\n";
    print $ofh "</tr>\n";

}


sub util_HtmlTableEnd{
	my ($ofh) = @_ ;
	print $ofh "</table>\n";
}



sub util_HtmlTableCell{
	my ($str) = @_ ;
	return "<td>$str</td>";
}



sub util_table_print{
	my ($table) = @_ ;
	foreach my $k (keys %{$table}){
		print "Tableprint $k $table->{$k} \n";
	}
}


sub util_MakeLink{
	my ($nm,$link) = @_ ;
    return  "<a href=\"$link\"> $nm</a>";
}

sub util_EC_CorrelatePDBS{
	my ($info,$a,$b,$VALUE) = @_ ; 
	print "util_EC_CorrelatePDBS for $a $b\n";
	my $x = util_getECfromPDB($info,$a);
	my $y = util_getECfromPDB($info,$b);
	if(!defined $x || !defined $y){
		print "Could not get EC for $a \n" if(!defined $x);
		print "Could not get EC for $b \n" if(!defined $y);;
		return undef;
	}

	my @ec1 = @{$x};
	my @ec2 = @{$y};
	my $ec1 = $ec1[0];
	my $ec2 = $ec2[0];
	if(!defined $ec1 || !defined $ec2){
		print "Could not get EC for $a \n" if(!defined $ec1);
		print "Could not get EC for $b \n" if(!defined $ec2);;
		return undef;
	}
	print "util_EC_CorrelatePDBS for $ec1 $ec2\n";

	$ec1 =~ s/\./YYY/g;
	$ec2 =~ s/\./YYY/g;
	my @l1 = split "YYY", $ec1 ;
	my @l2 = split "YYY", $ec2 ;
   
   my $N1 = @l1 -1 ;
   my $N2 = @l2 -1 ;
   my $score = abs($N1 - $N2);

   foreach my $n (0..$N1){
			my $v1 = $l1[$n] ; 
			my $v2 = $l2[$n] ; 
			if($v1 != $v2){
				$score = $score + $VALUE/($n+1) ; 
			    print " Found mismatch $n $score $v1 $v2\n";
				last ;
			}
   }
   return $score ; 
}

sub util_EC_AddPDB{
	my ($info,$pdb) = @_ ; 
	my $ec = util_getECfromPDB($info,$pdb);
	return $ec if(!defined $ec);
	my @l = split "\.", $ec ;
    
   my $N = @l -1 ;
   my $obj = {} ;
   foreach my $n (0..$N){
			my $v = $l[$n] ; 
		    $obj->{$n}->{$v} = [] if(!exists $obj->{$n}->{$v}) ;
			push @{$obj->{$n}->{$v}}, $pdb ; 
   }
}


sub util_EC_CreateLevels{
	my ($ecdone) = @_ ; 
    my $MAXLEVEL = 0 ;
    my $obj = {} ; 
    foreach my $ec (sort keys %{$ecdone}){
	    my @l = split "\.", $ec ;
	    $MAXLEVEL = @l if(@l > $MAXLEVEL);
    
	    my $N = @l -1 ;
	    foreach my $n (0..$N){
		    my $obj->{$n} = [];
	    }
    }
	return ($obj,$MAXLEVEL) ;
}


sub util_readPeptideInfo{
   my ($info,$nm,$infile) = @_ ;
   $info->{$nm} = {};
   die "ERROR: util_readPeptideInfo $infile does not exist" if(! -e $infile);
   my $ifh = util_read($infile);
   while(<$ifh>){
        next if(/^\s*$/);

        if(/Average Residue Weight/){
           my ($charge) = (/Charge\s*=\s*(.*)/) or die;
           $info->{$nm}->{CHARGE} = $charge ;
       }
	   if(/Residues = /){
	   	    my ($nres) = (/Residues = (\d+)/) or die;
			$info->{$nm}->{NRES} = $nres ;
	   }
        if(/^(Molecular|Basic|Acidic|Polar)/i){
		   my (@l) = split ;
		   my $N = @l -1 ;
           $info->{$nm}->{$l[0]} = $l[$N]; ;
		}
   }
   if(defined $info->{$nm}->{Acidic} && defined $info->{$nm}->{Basic}){
       $info->{$nm}->{AcidBasic} = $info->{$nm}->{Acidic} + $info->{$nm}->{Basic} ;
       $info->{$nm}->{PAB} = $info->{$nm}->{Acidic} + $info->{$nm}->{Basic} + $info->{$nm}->{Polar} ;
   }
   close($ifh);
}


sub util_ReadLine{
		   my ($LINE) = @_ ;
		   my $len = length($LINE);
           my ($atomstr , $serialnum , $atomnm , $alt_loc , $resname , $chainId , $resnum , $codeforinsertion , $x , $y , $z );

           $atomstr = util_mysubstr($len,$LINE,1 ,  6);
           $serialnum = util_mysubstr($len,$LINE,7 , 11);


           $atomnm = util_mysubstrDontStripSpace($len,$LINE,13 , 16);
           $alt_loc = util_mysubstr($len,$LINE,17,1);
           $resname = util_mysubstr($len,$LINE,18 , 20);
           $chainId = util_mysubstr($len,$LINE,22,1);
           $resnum = util_mysubstr($len,$LINE,23 , 26);
           $codeforinsertion = util_mysubstr($len,$LINE,27,1);
           $x = util_mysubstr($len,$LINE,31 , 38);
           $y = util_mysubstr($len,$LINE,39 , 46);
           $z = util_mysubstr($len,$LINE,47 , 54);
		   return ($atomstr , $serialnum , $atomnm , $alt_loc , $resname , $chainId , $resnum , $codeforinsertion , $x , $y , $z ); 
}
sub util_getECID{
	my ($ec,$level) = @_ ; 
	$ec =~ s/\./YYY/g ; 
	my @l = split "YYY",$ec ; 
	my $str = "";
	my $first = 1 ; 
	foreach my $i (1..$level){
		if(!$first){
			$str = $str . ".";
		}
		$str = $str . $l[$i -1];
		$first = 0 ; 
	}
	return $str ; 
}

sub util_uniq2 {
	my ($list) = @_ ;
    my %seen = ();
    my @r = ();
    foreach my $a (@{$list}) {
        unless ($seen{$a}) {
            push @r, $a;
            $seen{$a} = 1;
        }
    }
    return @r;
}
sub vSetVerbose{
	my ($val) = @_ ;
	my $ret = $ENV{VERBOSE};
	if(defined $ret){
		$ENV{VERBOSE} = $val ;
	}
}
sub vIncrVerbose{
	my $ret = $ENV{VERBOSE};
	if(defined $ret){
		$ENV{VERBOSE} = $ENV{VERBOSE} + 1 ;
	}
}
sub vDecrVerbose{
	my $ret = $ENV{VERBOSE};
	if(defined $ret){
		$ENV{VERBOSE} = $ENV{VERBOSE} - 1 ;
	}
}

sub vprint{
	my ($str) = @_ ;
	my $ret = $ENV{VERBOSE};
	if(defined $ret && $ret > 0 ){
		my $tab = "";
		foreach my $i (1..$ret){
			$tab = $tab. "\t";
		}
	    print STDERR "$tab$str\n";
	}
}
sub vprintheader{
	my ($str) = @_ ;
	my $ret = $ENV{VERBOSE};
	if(defined $ret && $ret > 0){
		my $tab = "";
		foreach my $i (1..$ret){
			$tab = $tab. "\t";
		}
	    print STDERR "\n\n======================================================================\n";
	    print STDERR "$tab$str\n";
	    print STDERR "======================================================================\n";
	}
}
sub util_copy_table{
	my ($table) = @_ ; 
	my $ret = {};
	foreach my $k (keys %{$table}){
		$ret->{$k} = $table->{$k}; 
	}
	return $ret; 
}
sub util_GetFastaFiles{
	my ($FASTADIR,@pdbs) = @_ ; 
    my $mapinfo ;
    my $fhnotfound = util_write("list.notfound");
    my @files = ();
    foreach my $i (@pdbs){
	    $i = uc($i);
        $i =~ /^\s*$/;
        my @f = <$FASTADIR/$i*fasta>;
	    my $j = $f[0];
	    if(!defined $j){
		    warn "Did not find fasta file for pdb $i in dir $FASTADIR \n";
		    print $fhnotfound "$i\n";
            #push @ignored, $i;
		    next ;
	    }
	    print " pushing $j \n" ;
        push @files, $j;
	    $mapinfo->{$j} = $i ;
    }
	return ($mapinfo,@files) ; 
}

sub util_WriteFastaFromAtoms{
    my ($pdb,$allatoms,$fastafh,$origpdb) = @_ ; 
    my @allresidues ;
    my $allres  = {};
    foreach my $atom (@{$allatoms}){
		my $nm = $atom->GetName();
		next if($nm =~ /HOH/);
	    my $resnum = $atom->GetResNum();
	    my ($res) = $pdb->GetResidueIdx($resnum);
	    push @allresidues ,$res ; 
	    $allres->{$res->GetResNum()} = $res ; 
    }
    my $allresiduesN = @allresidues ;
    my $s2 = "";
    my $s1 = "";
    foreach my $i (sort  { $a <=> $b }  keys %{$allres}){
	    my $r = $allres->{$i} ; 
	    my $s = $r->PrintSingleLetter($pdb);
	    $s1 = $s1 .  "$s$i," ;
	    $s2 = $s2 . "$s" ;
    }
    print $fastafh "\>$origpdb.$s1;\n";
    print $fastafh "$s2\n";
}


sub util_WriteFastaFromResidueNumbers{
    my ($pdb,$resnumbers,$fastafh,$origpdb) = @_ ; 
    my @allresidues ;
    my $allres  = {};
    foreach my $resnum (@{$resnumbers}){
	    my ($res) = $pdb->GetResidueIdx($resnum);
	    push @allresidues ,$res ; 
	    $allres->{$res->GetResNum()} = $res ; 
    }
    my $allresiduesN = @allresidues ;
    my $s2 = "";
    my $s1 = "";
    foreach my $i (sort  { $a <=> $b }  keys %{$allres}){
	    my $r = $allres->{$i} ; 
	    my $s = $r->PrintSingleLetter($pdb);
	    $s1 = $s1 .  "$s$i," ;
	    $s2 = $s2 . "$s" ;
    }
    print $fastafh "\>$origpdb.$s1;\n";
    print $fastafh "$s2\n";
}

sub util_GetPotForAtom{
	my ($a,$pqr,$pots) = @_ ;
	croak "not defined" if(!defined $a);
	my $number = $a->GetResNum();
	#print STDERR "kkkkkkkkk $number \n";
	my $atomnm = $a->GetType();
    my ($aPqr) = $pqr->GetAtomFromResidueAndType($number,$atomnm) or die ;
    die "could not find $number $atomnm" if(!defined $aPqr);

    my ($x,$y,$z) = $a->Coords();
    my ($x1,$y1,$z1) = $aPqr->Coords();
	if(1 && !util_IsZero($x-$x1+$y -$y1+$z-$z1)){
			# this will mismatch as rotation is done
             #warn "Warning: $x,$y,$z $x1,$y1,$z1 do not match" ; 
	}

    #my ($i1) = $a->GetIdx();
    my ($i2) = $aPqr->GetIdx();
    #imp -1 
	my $NPots = @{$pots};
    my $pot = $pots->[$i2-1] or die "Expected to find potential for residue number $number i2=$i2 and $NPots";
	return $pot ; 
}

sub util_ReadPdbs{
	my ($PDBDIR,$APBSDIR,$readpotential,@P) = @_ ; 
	my @ret ; 
	die "Expected at least one protein" if(!@P);
	foreach my $p1 (@P){
         my $file1 = "$PDBDIR/$p1.pdb";
         my $PPP = new PDB();
         $PPP->ReadPDB($file1);
	     print STDERR "Reading $p1\n";

	     my $pqrfile = "$APBSDIR/$p1/$p1.pqr";
	     my $pqr = new PDB();
	     my @pots = ();
		 if($readpotential){
		      $pqr->SetReadCharge(1);
	          $pqr->ReadPDB($pqrfile);
	          my $potential = "$APBSDIR/$p1/pot1.dx.atompot";
	          util_readAPBSPotential(\@pots,$potential);
		 }

		 my $info->{PDBNAME} = $p1 ;
		 $info->{PDBOBJ} = $PPP ;
		 $info->{PQR} = $pqr ;
		 $info->{POTS} = \@pots ;
		 push @ret , $info ; 
	}
	return @ret ;
}

sub util_WriteClustalAln{
	my ($protein1,$matches,$matchedProteins,$alnfh,$map,$annMap) = @_ ; 
	my @matchedProteins = @{$matchedProteins} ; 
	my $N = @matchedProteins ; 
	my $halfN = $N/2 ;
	my $quarterN = $halfN/2 ;
	my @matches = @{$matches} ; 
	my $first = 1 ; 
	my $EXTEND = {};
	while(@matches){
		my $protein2 = shift @matchedProteins ; 
		my $MATCH = shift @matches ; 
		if($first){
              print $alnfh "CLUSTAL 2.1 multiple sequence alignment\n\n\n";
			  my $pdb1 = $map->{$protein1} ;
	          my $mappedname = exists $annMap->{$protein1} ? $protein1. "." . $annMap->{$protein1} : $protein1 ;
		      my $XXX =  sprintf ( "%-12s",  $mappedname); 
              print $alnfh "$XXX";
			  my $CNT = 0 ; 
			  foreach my $resnum (sort {$a <=> $b}  keys %{$MATCH}){
			  	 $CNT++ ; 
				 $EXTEND->{$CNT} = {};
				 $EXTEND->{$CNT}->{CNT} = 1 ; 
				 $EXTEND->{$CNT}->{MATCHES} = {};
	             my ($res) = $pdb1->GetResidueIdx($resnum);
	             my $s = $res->PrintSingleLetter($pdb1);
				 $EXTEND->{$CNT}->{MATCHES}->{$s} =  1 ; 
                 print $alnfh "$s";
			  }
              print $alnfh "\n";
			  $first = 0 ;
		}


		my $pdb2 = $map->{$protein2} ;
	    my $mappedname = exists $annMap->{$protein2} ? $protein2. ".". $annMap->{$protein2} : $protein2 ;
		my $XXX =  sprintf ( "%-12s",  $mappedname); 
        print $alnfh "$XXX";
		my $CNT = 0 ; 
		foreach my $k (sort {$a <=> $b}  keys %{$MATCH}){
			 $CNT++ ; 
			 my $resnum = $MATCH->{$k} ;
			 my $s = "-";
			 if($resnum ne "-"){
				  $EXTEND->{$CNT}->{CNT} =  $EXTEND->{$CNT}->{CNT} + 1 ; 
	              my ($res) = $pdb2->GetResidueIdx($resnum);
	              $s = $res->PrintSingleLetter($pdb2);
				  $EXTEND->{$CNT}->{MATCHES}->{$s} =  1 ; 
			 }
             print $alnfh "$s";
		}
        print $alnfh "\n";
	}

	foreach my $CNT (sort {$a <=> $b}  keys %{$EXTEND}){
		my $cnt = $EXTEND->{$CNT}->{CNT} ;
		if($cnt >= (3*$quarterN)){
		   my $res = $EXTEND->{$CNT}->{MATCHES} ;
		   my @keys = (keys %{$res});
		   my $str = join "|" , @keys ;
		   $str = "(" . $str . ")";
		   print "$CNT $cnt $str ========= \n";
		}
	}

	
}

sub util_GetClosestAtoms_intwoPDBs{
    my ($p1,$p2,$PDBDIR,$maxdist) = @_ ; 
    my $file1 = "$PDBDIR/$p1.pdb";
    my $file2 = "$PDBDIR/$p2.pdb";
    my $pdb1 = new PDB();
    $pdb1->ReadPDB($file1);
    my $pdb2 = new PDB();
    $pdb2->ReadPDB($file2);
    
    my @reslist = $pdb1->GetResidues();
    
    my @atoms ;
    while(@reslist){
        my $r = shift @reslist ;
        my @aaa = $r->GetAtoms();
    	push @atoms, @aaa;
    }
    
    my @resultsall ; 
    my $DONE ;
    foreach my $atom (@atoms){
         my $list = util_make_list($atom);
         my ($junk,$neighatoms)  = $pdb2->GetNeighbourHoodAtom($list,$maxdist);
    	 foreach my $r (@{$neighatoms}){
    	       my $atomstr = $r->GetAtomStr();
    		   next if($atomstr eq "HETATM");
    
    	        my $d = $atom->Distance($r) ;
    			my $nm = $atom->GetName() . " -> " . $r->GetName();
    			my $info = {};
    	        $info->{NAME} = $nm;
    	        $info->{SCORE} = $d;
    	        push @resultsall, $info ;
    	 }
    
    }
    
    my @resultssorted = sort { $a->{SCORE} <=> $b->{SCORE} } @resultsall ;
    my $CNT = 0 ; 
    foreach my $r (@resultssorted){
    	$CNT++;
    	my $nm = $r->{NAME};
    	my $score = $r->{SCORE};
    	print STDERR "NAME = $nm score = $score \n";
    	last if($CNT eq 10);
    }
    return @resultssorted ;
}


sub util_Ann2Simple{
	my ($infile,$outfile) = @_; 
    my $ofh ;
    $ofh = util_write($outfile) if(defined $outfile);
    my $ifh = util_read($infile);
	my @retlist  ; 
    while(<$ifh>){
         next if(/^\s*$/);
         chop ;
	     if(/^POINTS/){
	 	    s/POINTS//g;
		    s/\// /g;
		    my @l = split " ", $_ ; 
		    while(@l){
			    my $a = shift @l ;
			    my $b = shift @l ;
			    #$a =~ s/\s*//g;
			    #$b =~ s/\s*//g;
			    print  $ofh "$b$a " if(defined $ofh);
				push @retlist, $a ;
		    }
		    print $ofh "\n" if(defined $ofh);
	     }
    }
	return @retlist ;
}

sub util_GetPotDiffForAtoms{
     my ($pdb1,$pqr1,$pots1,$a,$b) = @_ ; 
     my $pota = util_GetPotForAtom($a,$pqr1,$pots1) ;
     my $potb = util_GetPotForAtom($b,$pqr1,$pots1) ;
	 my $diff = $pota - $potb ;
	 return $diff;
}

sub util_GetPotDiffForResidues{
    my ($pdb1,$pqr1,$pots1,$res1,$res2,$what) = @_ ; 
	my $a = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),$what);
	my $b = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),$what);
	my $diff = util_GetPotDiffForAtoms($pdb1,$pqr1,$pots1,$a,$b);
}

sub util_ProcessSingleLine{
     my ($pdb1,$pqr1,$pots1,$line) = @_ ; 
	 my $atomlist = $pdb1->ParseResultLine($line);
	 my @names ; 
	 foreach my $a (@{$atomlist}){
        my $pot = util_GetPotForAtom($a,$pqr1,$pots1) ;
		#push @pots, $pot ;
		push @names, $a->GetName();
	 }
	 my $name = join ",",@names ; ;
	 my @dist = @{$pdb1->DistanceInGivenSetOfAtoms($atomlist)};
	 my @pots = @{$pdb1->PotInGivenSetOfAtoms($atomlist,$pqr1,$pots1)};
	 return (\@dist,\@pots,$name);
}

sub util_FindRmsd{
	my ($pdb1,$pdb2) = @_ ;
    
    my @res = $pdb1->GetResidues();
    my $N = @res;
    my $cnt = 0 ;
    my $sum = 0 ;
    my $cntmatch = 0 ; 
    foreach my $res (@res){
        next if($res->GetAtomStr() ne "ATOM");
	    my $resnumA = $res->GetResNum() ;
	    my $resnumB = $res->GetResNum() ;
        my $CAatom1 = $pdb1->GetAtomFromResidueAndType($resnumA,"CA");
        my $CAatom2 = $pdb2->GetAtomFromResidueAndType($resnumB,"CA");
	    my $d = util_format_float($pdb1->DistanceAtoms($CAatom2,$CAatom1),1);
        $cnt++;
	    $sum = $sum + $d * $d ; 
    }
    
    my $rmsd = util_format_float(sqrt($sum/$cnt),3) ; 
    print  " $rmsd $cnt\n";
    return $rmsd ;
}

sub util_GetMeanSD{
    my ($container) =@_ ;
	my $mean = Math::NumberCruncher::Mean($container) or warn "Mean not found" ;
	my $sd = Math::NumberCruncher::StandardDeviation($container) or warn "sd not found" ;
	return ($mean,$sd);
}

sub util_FindRmsdAllAtoms{
	my ($pdb1,$pdb2) = @_ ;
    
    my @atoms = $pdb1->GetAtoms();
    my $N = @atoms;
    my $cnt = 0 ;
    my $sum = 0 ;
    my $cntmatch = 0 ; 
    foreach my $atom1 (@atoms){
	    my $type = $atom1->GetType();
	    my $resnum = $atom1->GetResNum() ;
        my $atom2 = $pdb2->GetAtomFromResidueAndType($resnum,$type);
		next if (!defined $atom2);
	    my $d = util_format_float($pdb1->DistanceAtoms($atom1,$atom2),1);
        $cnt++;
	    $sum = $sum + $d * $d ; 
    }
    
    my $rmsd = util_format_float(sqrt($sum/$cnt),3) ; 
    print  " $rmsd $cnt\n";
    return $rmsd ;
}
sub util_sortsingleString{
   my $s = shift ;
   my @sl = split "", $s ;
   my @XX = sort @sl ; 
   
   my $rev = join "", @XX ;
   return $rev ; 
}
sub util_AreResiduesContinuous{
	my ($pdb1,$res1,$res2) = @_ ;
	my $CA1 = $pdb1->GetAtomFromResidueAndType($res1->GetResNum(),"CA");
	my $CA2 = $pdb1->GetAtomFromResidueAndType($res2->GetResNum(),"CA");
    my $d1 = util_format_float($pdb1->DistanceAtoms($CA1,$CA2),1);
    my $diff1 = abs ($d1 - 3.8);
    return (0,$d1,$diff1) if($diff1 > 0.3);
	return (1,$d1,$diff1) ;
}
sub util_IsPro{
	my ($res) = @_ ;
	my $name = $res->GetName();
	return 1 if($name eq "PRO");
	return 0 ; 
}
sub util_readfasta{
    my ($infile) =@_ ; 
    my $str = "";
    my $ifh = util_read($infile);
	my $firstline ; 
    while(<$ifh>){
         if(/^\s*>/){
	 	    $firstline = $_ ; 
		    next ; 
	     }
         next if(/^\s*$/);
	     chop ;
	     $str = $str . $_ ; 
    }
    $str =~ s/\s*//g;
    return ($str,$firstline) ; 
}

sub util_ExtractSliceFromFasta{
	my ($ofh,$infile,$start,$end) = @_ ; 
    my ($str,$firstline) = util_readfasta($infile);

    chop $firstline ;
    my $time = int(time() *rand());
    print "$time";
	$time = "$start.$end";
    
    print $ofh ">$time.$firstline  \n";
    
    my @l = split "", $str ; 
    my $N = @l ;
    print "$N sll \n";
    foreach my $i ($start..$end){
	    $i = $i - 1 ; 
	    print $ofh "$l[$i]";
    }
    print $ofh "\n";
}


## THIS NEEDS TO BE FIXED FOR FRAGMENTCOMPARE.PL ###
sub util_ReadAnnotateFile{
	my ($infile,$DIFF) = @_ ; 
	$DIFF = 50 if(!defined $DIFF);
    my $ifh = util_read($infile);
    my $info = {};
    while(<$ifh>){
         chop; 
         next if(/^\s*$/);
	     if(/^\s*(Repeat|Region)/){
	         my (@l) = split ; 
		     my $start = $l[1];
		     my $end = $l[3];
		     my $diff = abs($start - $end);
		     next if($diff > $DIFF);
    
		     my $anno = $_ ;
		     print "$start $end $anno \n";
		     $info->{$start} = $anno ;
		     $info->{$end} = $anno ;
	     }
	     if(/^\s*Modified/){
	         my (@l) = split ; 
		     my $start = $l[2];
		     my $anno = $_ ;
		     $info->{$start} = $anno ;
	     }
	 	    
    }
	return $info ;
}

sub util_ReadAnnotateFileFRAGAL{
	my ($infile,$DIFF) = @_ ; 
	$DIFF = 50 if(!defined $DIFF);
    my $ifh = util_read($infile);
    my $inforepeatregion = {};
    my $infomodified = {};
	my $CNT = 0; 
    while(<$ifh>){
         chop; 
         next if(/^\s*$/);
		 $CNT++;
	     if(/^\s*(Repeat|Region)/){
	         my (@l) = split ; 
		     my $start = $l[1];
		     my $end = $l[3];
		     my $diff = abs($start - $end);
		     if($diff > $DIFF){
			 	print "DIFF $diff is freater than $DIFF\n";
				next ;
			 }
    
		     my $anno = $_ ;
		     $inforepeatregion->{$CNT}->{START} = $start;
		     $inforepeatregion->{$CNT}->{END} = $end;
	     }
	     if(/^\s*Modified/){
	         my (@l) = split ; 
		     my $start = $l[2];
		     my $anno = $_ ;
		     $infomodified->{$CNT}->{START} = $start ;
	     }
	 	    
    }
	return ($inforepeatregion,$infomodified) ;
}


sub util_SortTwoStrings{
	my ($a,$b) = @_ ; 
	if($a lt $b){
		return ($a, $b);
	}
	else{
		return ($b, $a);
	}
    
}

sub util_ParseAAGroups{
	my ($in) = @_ ; 
    my $ifh = util_read($in);
	my $grp = 0 ; 
	my $info ={};
	my @grps ;
	while(<$ifh>){
        next if(/^\s*$/);
	    my (@l) = split ; 
		$grp++;
		my $NM ; 
	    while(@l){
	 	   my $single = shift @l ; 
		   if(!defined $NM){
		       $NM = $single ;
			   push @grps, $single ;
		   }
		   #$info->{$single} = $grp ; 
		   $info->{$single} = $NM ; 
		   print "$single \n";
	 	   shift @l ; 
	 	   shift @l ; 
	 	   shift @l ; 
	    }
	}
	return ($info,\@grps);
}
