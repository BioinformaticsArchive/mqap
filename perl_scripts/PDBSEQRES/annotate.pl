#!/usr/bin/perl -w 
use strict ;
use FileHandle ;
use Getopt::Long;
use Cwd ;
use MyUtils;
use MyWeb;
use PDB ;
use ConfigPDB;
use POSIX qw(floor);
my $commandline = util_get_cmdline("",\@ARGV) ;
my ($promfile,$html,$all,$infile,$outfile,$scores,$or,$silent,$groupinfo,$pdb);
my ($addto,$matches,$DIR,$listfile,$query2ref,$mapping);
my $howmany = 600000 ; 
my ($WEIGHTEC) = $ENV{WEIGHTEC} ;
print "WEIGHTEC = $WEIGHTEC  \n";
my $threshhold = 2 ; 
my $cutofflength = 0 ; 
my $isdummy = 0 ; 
my @types = (); 
my @ntypes = (); 
my @motifs = (); 
my $caption = "XXXXXXXXXXXXXXXXXXXXX";
my $header1 = "XXXXXXXXXXXXXXXXXXXXX";
my $header2 = "";
my $title = "CLASP Database";
my $ANNFILEDIST = 0 ;
GetOptions(
            "all"=>\$all ,
            "query2ref"=>\$query2ref ,
            "groupinfo"=>\$groupinfo ,
            "scores"=>\$scores ,
            "silent"=>\$silent ,
            "mapping"=>\$mapping ,
            "infile=s"=>\$infile ,
            "promidx=s"=>\$promfile ,
            "pdb=s"=>\$pdb ,
            "title=s"=>\$title ,

            "addto=s"=>\$addto ,
            "html=s"=>\$html ,
            "header1=s"=>\$header1 ,
            "header2=s"=>\$header2 ,

            "dir=s"=>\$DIR ,
            "listfile=s"=>\$listfile ,
            "howmany=i"=>\$howmany ,
            "matches=s"=>\$matches ,
            "anndist=i"=>\$ANNFILEDIST ,
            "isdummy=i"=>\$isdummy ,
            "or=i"=>\$or ,
            "cutofflength=i"=>\$cutofflength ,
            "type=s"=>\@types,
            "caption=s"=>\$caption,
            "ntype=s"=>\@ntypes,
            "motif=s"=>\@motifs,
            "outfile=s"=>\$outfile 
           );
die "Dont recognize command line arg @ARGV " if(@ARGV);
usage( "Need to give a input file name => option -infile ") if(!defined $infile);
usage( "Need to give a listfile -option -listfile  ") if(!defined $listfile);
$outfile = $listfile . ".annotated"  if(!defined $outfile);
my $ofh = util_write($outfile);
my ($grpconfig) = $ENV{CONFIGGRP} or die ;
my ($ANNDIR) = "ANNOTATE";
my ($MAPPINGFILE) = $ENV{MAPPINGFILE} or die ;
my ($infoMapping,$uniqueEC,$uniqueSP) = util_read_Mapping_PDB_2_SWISSPROT($MAPPINGFILE);
ConfigPDB_Init($grpconfig);

my ($RESULTDIR,$PDBDIR,$FASTADIR,$APBSDIR,$FPOCKET,$SRC) = util_SetEnvVars();


my $activesitesoverlap = {};
my @list= util_read_list_sentences($listfile);
my $list = {};
if(defined $scores){
	my @l ;
    map { my ($score,$name) = split  ;  $list->{lc($name)} = $score ; push @l, $name ; } @list ;
	@list = @l ;
}
else{
    map { s/\s*//g ;  $list->{lc($_)} = 1 ; } @list ;
}


    print STDERR "Info: parsing file $infile - might take some time\n";

	my $info = util_parsePDBSEQRES($infile,0);
	my @p ;
	my $doubleslashes = "";
	my @tableheaders ;
	my $cellentries = {} ;
	if(defined $html){
		@tableheaders  = ( "PDB ID ", "Description" , "Sequence length");
		if(defined $scores ){
			push @tableheaders, " Score " ;
			push @tableheaders, " Is any predicted residue in active site "  ;
		}
		else{
			push @tableheaders, " Active residues specified " if(!defined $query2ref && !$isdummy);
		}
	}
	else{
		$doubleslashes = "\\\\";
	    util_printTablePre($ofh,$caption);
	}

		my $ofhmatches ; 
        if(defined $matches){
		     $ofhmatches = util_write("$matches.possiblefunctions");
		}

	my $cnt = 0 ;
	my $nm2Orig = {} ;
    map { 
	    my $nm = uc($_);
	    my $orignmnm = uc($_);
	    my $lc = lc($_);
		my $ec ;
        if(defined $mapping){
            #my ($infoMapping,$uniqueEC,$uniqueSP) = util_read_Mapping_PDB_2_SWISSPROT($MAPPINGFILE);
            my $x = util_getECfromPDB($infoMapping,$lc);
	        if(defined $x && @{$x} > 0){
		        $ec = $x->[0];
		        #print "$lc $ec \n";
	        }
        }


		my ($tableResidues,$nresidues,$juuunk) ;
		my $EXISTSINACTIVESITE = "No" ;
		my $h = $info->{$lc} ; 
		if(!defined $h){
		    warn "did not fine $lc ";
	    }
		else{
			($tableResidues,$nresidues,$juuunk) =  Config_ReadAnnfile($nm,$ANNDIR,0);
		    $EXISTSINACTIVESITE = "Dont know active residues" if($nresidues == 0);
			my ($closetoactivesitePDB,$dist) =  Config_ReadAnnfileClose($pdb,$ANNDIR,0);
			$ANNFILEDIST = $dist if($ANNFILEDIST eq 0);



			###########    Get the first entry #############
			if(defined $html){
					if(defined $scores){
						   my $resultfile = defined $query2ref ? "$pdb.$nm.pdb.out.txt" : "$nm.$pdb.pdb.out.txt" ; 
						   my $potfile =  defined $query2ref ? "$pdb.$nm.potential.diff.txt" : "$nm.$pdb.potential.diff.txt" ; 
						   my $disfile =  defined $query2ref ? "$pdb.$nm.distance.diff.txt" : "$nm.$pdb.distance.diff.txt" ; 

				           $nm = $nm . web_makeLink("(Predicted active site)",$resultfile,$isdummy);
				           $nm = $nm . web_makeLink("(Potential difference)",$potfile,$isdummy);
				           $nm = $nm . web_makeLink("(Distance difference)",$disfile,$isdummy);
						   $nm2Orig->{$nm} = $orignmnm ; 

						   $resultfile = defined $query2ref ? "$pdb.$orignmnm.pdb.out" : "$orignmnm.$pdb.pdb.out" ; 
                           my @r= ConfigPDB_ParseResultsFile($resultfile,1);
						   if(1){
			                   foreach my $result (@r){
                                   my @atoms = @{$result->{ATOMS}}; 
								   my $first = 1 ; 
							       foreach my $a (@atoms){
							          my ($r,$n) = split "/",$a;
									  if(defined $query2ref){
					                      if(exists $closetoactivesitePDB->{"$r.$n"}){
										  	if(! defined $activesitesoverlap->{$pdb.$orignmnm}){
										  	$activesitesoverlap->{$pdb.$orignmnm} = "$r.$n";
											}
											else{
										  	$activesitesoverlap->{$pdb.$orignmnm} = $activesitesoverlap->{$pdb.$orignmnm} . " ".  "$r.$n";
											}

										  }
										  else{
										  }
									  }

									  
					                  if(exists $tableResidues->{"$r.$n"}){
									  	my $nn = $r . $n . " " ; 
										$EXISTSINACTIVESITE  = "" if($first);
		                                $EXISTSINACTIVESITE = $EXISTSINACTIVESITE . $nn ; 
										$first = 0 ; 
								      }
							       }
			                   }
						   }
					}
					else{
						if(!defined $query2ref){
				           $nm = web_makeLink($nm,"$html/$nm.single.sorted.annotated",$isdummy);
						}
						else{
				           $nm = web_makeLink($nm,"$html/$nm.3.sorted.annotated",$isdummy);
						}
					}
			}

			my $possiblefunctions = "";
			if(-e "Matches/$nm.possiblefunctions"){
			    my $fh = util_read("Matches/$nm.possiblefunctions");	
				while(<$fh>){
					chomp ;
					$possiblefunctions = $_ ; 
					last ;
				}
				
			}


			if($h->{LEN} > $cutofflength && $cnt < $howmany ){
				if(defined $scores){
				    my $score = $list->{$lc};
					if(defined $html){
						  my @l = ( $nm,  $h->{FULLNM}  , $h->{LEN} , $score);
						  push @l , $EXISTSINACTIVESITE  ;
				          $cellentries->{$cnt} = \@l ;
					}
					else{
		                  print $ofh "$nm,$ec,$h->{LEN} &  $h->{FULLNM} & $possiblefunctions &   $score $nresidues $doubleslashes \n";
						  if(defined $matches  && $cnt < 5){
						  	print $ofhmatches " $h->{FULLNM},";
						  }
					}
				}
				else{
					if(defined $html){
						  my $str = "";
						  my @l = ( $nm, $h->{FULLNM},  $h->{LEN});
						  $str = $str . util_HtmlTableCell($nm);
						  $str = $str . util_HtmlTableCell($h->{FULLNM});
						  $str = $str . util_HtmlTableCell( $h->{LEN});
						  my $t =  web_makeLink($nresidues,"ANNOTATE/$orignmnm.outconf.annotated.txt",$isdummy);
						  push @l, $t if(!defined $query2ref && !$isdummy);
				          $cellentries->{$cnt} = \@l ;
					}
					else{
						  #my @p = split ",", $possiblefunctions ; 
		                  #print $ofh "$nm & $ec & $h->{LEN} &  $h->{FULLNM} & $p[0], $p[1], &   $nresidues $doubleslashes \n";
		                  #print $ofh " &  &  &  & $p[2], $p[3], $p[4] &   $nresidues $doubleslashes \n";
		                  print $ofh "$nm &  $h->{LEN} &  $h->{FULLNM} &  $nresidues $doubleslashes \n";
						  if(defined $matches  && $cnt < 5){
						  	my $llll = lc($h->{FULLNM});
						  	print $ofhmatches " $llll,  ";
						  }
					}
				}
				$cnt++;
			}
		}
	} @list ;
		if(defined $matches){
			print $ofhmatches  "\n";
			close($ofhmatches);
		}



	my $lc = lc($caption);
    my $h = $info->{$lc} ; 
	 $h->{FULLNM}  =  "HHH" if(! defined  $h->{FULLNM} );
	my $newcaption = $caption . " : " . $h->{FULLNM} ; 
	if(defined $html){
        web_printHtmlHead($ofh,$title);

        web_printTableHead($ofh,$header1,$header2,"tableid");
	    web_printTableHeader($ofh,@tableheaders);
		foreach my $c (0..$cnt-1){
			my @l = @{$cellentries->{$c}} ;
			web_printTableRow($ofh,@l);
		}
	    web_printTableEnd($ofh);

	    web_printHtmlEnd($ofh);


	}
	else{
	    util_printTablePost($ofh,$newcaption);
	}


if(defined $scores && defined $query2ref && defined $promfile){
		my $lc = lc($pdb);
		my $uc = uc($pdb);
		my $FFFHHH = util_write("$uc.matches");
		my $h = $info->{$lc} ; 
		my $LEN = $h->{LEN};
	my $promIndex = 0; 
	my $moonIndex = 0; 
    #my ($infoMapping,$uniqueEC,$uniqueSP) = util_read_Mapping_PDB_2_SWISSPROT($MAPPINGFILE);
    my $x = util_getECfromPDB($infoMapping,$pdb);
	if(defined $x && @{$x} > 0){
		my $ec = $x->[0];
		my $CNTOFMATCHES    = 0 ;
		my $CNTOFNOTMATCHES = 0 ;
        foreach my $c (0..$cnt-1){
	        my @l = @{$cellentries->{$c}} ;
		    my $N = @l - 1 ; 
		    my $score = $l[$N -1];
		    my $last = $l[$N];
		    my $nm = $l[0];
		    my $orignmnm = $nm2Orig->{$nm} or die ; 
		    next if($pdb eq $orignmnm);
		    if($score < $threshhold){
                my $sc = util_EC_CorrelatePDBS($infoMapping,$pdb,$orignmnm,$WEIGHTEC);
			    if(defined $sc){
			       $sc = $sc/$score ;
		           if(!defined $activesitesoverlap->{$pdb.$orignmnm}){
			           $moonIndex = $moonIndex + $sc ;
				       $CNTOFNOTMATCHES++;
		           }
				   else{
				       print " OVERKAP $pdb.$orignmnm  $activesitesoverlap->{$pdb.$orignmnm} \n";
					   print $FFFHHH "$orignmnm\n";
			           $promIndex = $promIndex + $sc ;
					   $CNTOFMATCHES++;
					}
			    }
		    }
        }
		my $TOTALMATCHES = $CNTOFMATCHES + $CNTOFNOTMATCHES ;
		my $append = util_append($promfile);
		die if(!defined $append);
	    print $append "$threshhold, $ANNFILEDIST, $promIndex, $moonIndex, $TOTALMATCHES , $CNTOFMATCHES , $CNTOFNOTMATCHES, $cnt ,$LEN  PROM score for $pdb with EC $ec  \n";

	}
	else{
		print "Could not get EC number for $pdb \n";
	}
}



print STDERR "Output written in $outfile\n";


sub usage{
    my ($msg) = @_ ;
    print $msg , "\n" ; 
print << "ENDOFUSAGE" ; 
ENDOFUSAGE
    die ;
}



