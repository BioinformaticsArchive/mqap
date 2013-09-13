
package BP;
use Carp ;
use POSIX ;
require Exporter;
use MyUtils ;
use Algorithm::Combinatorics qw(combinations) ;
 use Error qw(:try );

@ISA = qw(Exporter);
@EXPORT = qw( 
		BP_DoAlignment BP_SaveTree BP_SaveAlignment BP_GetSequence 
		BP_DoProfileAlignment
 		BP_Phylip 
		BP_Needle BP_Needle_parseout 
	    );

use strict ;
use FileHandle ;
use Getopt::Long;


my $verbose = 13 ;


use Bio::Perl;
use Bio::DB::SwissProt;
use Bio::Tools::Run::Alignment::Clustalw;
use Bio::AlignIO;
use Bio::Align::DNAStatistics;
use Bio::Align::ProteinStatistics;
use Bio::Tree::DistanceFactory;
use Bio::TreeIO;
use Bio::Tree::TreeFunctionsI; 
use Bio::Tree::Draw::Cladogram;

use Bio::Tools::Run::Phylo::Phylip::Consense;
use Bio::Tools::Run::Phylo::Phylip::SeqBoot;
use Bio::Tools::Run::Phylo::Phylip::ProtDist;
use Bio::Tools::Run::Phylo::Phylip::Neighbor;
use Bio::Tools::Run::Phylo::Phylip::DrawTree;



sub BP_DoAlignment{
   my ($infile,$id,$info) = @_ ; 
   my @listnumbers = util_read_list_sentences($infile);
   my    @params = ('ktuple' => 2, 'matrix' => 'BLOSUM');
   my    $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params);
   my    $ktuple = 3;


   my @seqarr = ();
   my $done = {};
   foreach my $pdbid (@listnumbers){
	    $pdbid =~ s/\s*//g ;
        $pdbid = lc($pdbid);
	    if(!exists $info->{$pdbid}->{SWISSID}){
	       warn "no swissid for $pdbid" ; 
		   #die ;
	       next ; 
	    }
   
	    my $swissid = $info->{$pdbid}->{SWISSID} ;
        $pdbid = uc($pdbid);
	    print  "$pdbid $swissid\n";
	    BP_GetSequence($id,$done,\@seqarr,$pdbid,$swissid,1);
   }


   my ($aln,$tree) = $factory->run(\@seqarr);
   
   BP_SaveTree($tree,$id);
   BP_SaveAlignment($aln,$id);

   #print "Running phylip\n";
   #BP_Phylip($aln);
    
   return ($factory,$aln,$tree,\@seqarr);
 
}

sub BP_SaveAlignment{
	my ($aln,$id) = @_ ; 
     my $out_file = "$id.config.aln";
     my $out_filephylip = "$id.config.phy";

     my $aln_out  = Bio::AlignIO->new(-file => ">$out_file", '-format' => 'clustalw');
     $aln_out->write_aln($aln);
     my $aln_outp  = Bio::AlignIO->new(-file => ">$out_filephylip", '-format' => 'phylip');
     $aln_outp->write_aln($aln);

	 my $dfactory = Bio::Tree::DistanceFactory->new(-method => 'NJ');
	 my $stats = Bio::Align::ProteinStatistics->new;
	 my $treeout = Bio::TreeIO->new(-format => 'newick');
	 my $mat = $stats->distance(-method => 'Kimura', -align  => $aln);
	 my $tree = $dfactory->make_tree($mat);
	 #$treeout->write_tree($tree);


	my $n1 = $tree->find_node('uvi31');
	#my $n2 = $tree->find_node('2QZ6.P85302..BL');
	my $n2 = $tree->find_node('3A3F.A8E0K8..PBP');
	if(defined $n1 && defined $n2){
	   my $h = $n1->height ;
	   my $dist = $tree->distance(-nodes => [$n1, $n2] );
	   print " DISTANCE $dist $h \n"; 
	}

	return $tree ; 
}
	
sub BP_Write_Newick{
	my ($tree,$id) = @_ ; 
    my $out = new Bio::TreeIO(-file => ">$id.nh", -format => 'newick');
    $out->write_tree($tree);
}

sub BP_Write_Nexus{
	my ($tree,$id) = @_ ; 
    my $out = new Bio::TreeIO(-file => ">$id.nex", -format => 'nexus');
    $out->write_tree($tree);
}

sub BP_Write_Phylip{
	my ($tree,$id) = @_ ; 
    #my $out = new Bio::TreeIO(-file => ">$id.ph", -format => 'phylip');
    #$out->write_tree($tree);
}


sub BP_SaveTree{
	my ($tree,$id) = @_ ; 
	print "Saving tree to $id.eps \n";

	BP_Write_Newick($tree,$id);
	BP_Write_Nexus($tree,$id);
	BP_Write_Phylip($tree,$id);


    my $obj1 = Bio::Tree::Draw::Cladogram->new(-bootstrap => 1,
                                           -tree    => $tree,
                                           -compact => 0);
    $obj1->print(-file => "$id.eps");
}




sub BP_GetSequence{
	my ($id,$done,$arr,$pdbid,$swissid,$write)= @_ ;
	return if(defined $done->{$swissid});

	my $filenm = "$pdbid.$id.$swissid.fasta";


    my $seq_object ;
	if(-e $filenm){
        my $seqin = Bio::SeqIO->new ( -file   => $filenm, -format => 'fasta');
        $seq_object = $seqin->next_seq();
	}
	else{
		 {
           $seq_object = get_sequence('swiss',$swissid);
		 }
	     if(defined $write){
            write_sequence(">$filenm",'fasta',$seq_object);
	     }
	}
    $done->{$swissid} = 1 ; 

	print " Getting swiss id $swissid \n";

    push @{$arr}, $seq_object if(defined $arr) ;
}


sub BP_DoProfileAlignment{
   my ($aln1,$aln2,$id1,$id2,$arr1,$arr2) = @_ ; 

   my @seqarr = ();
   push @seqarr,@{$arr1};
   push @seqarr,@{$arr2};

   my $id = "$id1.$id2";

   print " DOING $id1 and $id2 \n";

   my    @params = ('ktuple' => 3, 'matrix' => 'BLOSUM');
   my    $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params);


   my $aln = $factory->profile_align($aln1,$aln2);
   my $tree = BP_SaveAlignment($aln,$id);

   BP_SaveTree($tree,$id);

    
   return ($factory,$aln,$tree);
 
}


sub BP_Phylip{
  my ($aln) = @_ ; 
   

  my  @params = ('MODEL' => 'PAM');
  my $protdist_factory = Bio::Tools::Run::Phylo::Phylip::ProtDist->new(@params);
  my $matrix  = $protdist_factory->run($aln);

  #Create the tree passing in the distance matrix
  #my @params = ('type'=>'NJ','outgroup'=>2,'lowtri'=>1, 'upptri'=>1,'subrep'=>1);

  #my $neighbor_factory = Bio::Tools::Run::Phylo::Phylip::Neighbor->new(@params);

  #you can set your outgroup using either a number specifying
  #the rank in the matrix or you can just use the name of the
  #species

  #$neighbor_factory->outgroup(1);

  #my ($tree) = $neighbor_factory->run($matrix);


  #now draw the tree
  #my $draw_factory = Bio::Tools::Run::Phylo::Phylip::DrawTree->new();
  #my $image_filename = $draw_factory->draw_tree($tree); 
}

sub ParseArgFile{
	my ($arg) = @_ ;
	my $exec  = "needle " ;
    my $ifh = util_read($arg);
    while(<$ifh>){
         next if(/^\s*$/);
	     my ($nm,$junk) = split ; 
		 $exec = $exec . "-". $nm . " $junk " ;
    }
	return $exec ; 
}
sub BP_Needle{
	my ($outfile,$DIR,$f1,$f2,$arg) = @_ ;
	my $file1 = $DIR . "/" . $f1 ;
	my $file2 = $DIR . "/" . $f2 ;
	my $end = " -endopen 1 -endweight 1 -endextend 0.2";
	my $execinit = ParseArgFile($arg);
	print "INIT = $execinit \n";
    #$exec = "needle -gapopen 25  -gapex 0.5 -ou $outfile $file1 $file2  2> /dev/null ";
    my $exec = $execinit . "-ou $outfile $file1 $file2  2> /dev/null "; 
	system($exec);
}

sub BP_Needle_parseout{

   my ($outfile) = @_ ;

   my ($iden,$simi); 
   my $ifh = util_read($outfile);
   while(<$ifh>){
        next if(/^\s*$/);
		if(/Identity/){
			($iden) = (/.*\((.*)\)/);
			$iden =~ s/\%//;
		}
		if(/Similarity/){
			($simi) = (/.*\((.*)\)/);
			$simi =~ s/\%//;
		}
		
   }
	return ($iden,$simi);
}
