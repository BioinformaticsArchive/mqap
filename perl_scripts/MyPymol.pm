
package MyPymol;
use Carp ;
use POSIX ;
require Exporter;
use MyUtils;
no warnings 'redefine';
my $EPSILON = 0.01;

local $SIG{__WARN__} = sub {};

my $RAY = 0 ; 

@ISA = qw(Exporter);
@EXPORT = qw( 
		util_PrintPymolWith2Proteins util_PrintPymolResidue util_PrintPymolShell util_PrintPymolSingleProtein
		util_MakeMovieFromImages
		pymolin_getResultsLine
		pymolin_AddAtomstoPymolin
		pymolin_getResultsLineAll
		pymolin_getResultsLineAllFromList
		util_PrintPymolWithAllProteins
	    );

use strict ;
use FileHandle ;
use Getopt::Long;

my @colors = qw ( red yellow blue green cyan magenta orange);


sub util_PrintPymolWith2Proteins{
    my ($ofh,$pdb1,$pdb2,$list1,$list2) = @_ ; 

    util_PrintPymolShell($ofh,$pdb1,"topmatch_query");
    util_PrintPymolShell($ofh,$pdb2,"topmatch_target");




    print $ofh "delete all \n";

	## some general commands
    print $ofh "set_color carbon= [0.00 , 0.53 , 0.22] \n";

	print $ofh "set sphere_scale, 0.25, (all) \n";

    print $ofh "load_embedded topmatch_query,name=PDBA,state=1,discrete=0 \n";
    print $ofh "load_embedded topmatch_target,name=PDBB,state=1,discrete=0 \n";
    print $ofh "hide everything, PDBA or PDBB \n";
    print $ofh "select query, PDBA  \n";
    print $ofh "select target, PDBB  \n";
    print $ofh "bg_color white \n";
    print $ofh "set specular, 0 \n";
    print $ofh "color grey, PDBA \n";
    print $ofh "color wheat, PDBB \n";
    print $ofh "color slate, query \n";
    print $ofh "color limegreen, target \n";
    print $ofh "show cartoon, query or target \n";
    print $ofh "zoom query or target \n";

	my $cnt = 0 ; 
    $cnt = util_PrintPymolResidue($ofh,"query",$list1,$cnt,"red") if(defined $list1);
    $cnt = util_PrintPymolResidue($ofh,"target",$list2,$cnt,"yellow") if(defined $list2);

}


sub util_PrintPymolSingleProtein{
    my ($ofh,$pdb1,$list1,$list2,$infile,$formustang) = @_ ; 

    util_PrintPymolShell($ofh,$pdb1,"topmatch_target");



    print $ofh "delete all \n";

    PrintColorName($ofh);

    print $ofh "set_color carbon= [0.8 , 0.8 , 0.8] \n";
    print $ofh "load_embedded topmatch_target,name=PDBB,state=1,discrete=0  \n";
    print $ofh "set transparency = 0.9  \n";
    print $ofh "hide everything, PDBB  \n";
    print $ofh "select target, PDBB   \n";
    print $ofh "bg_color white  \n";
    print $ofh "set specular, 0  \n";
    print $ofh "color wheat, PDBB  \n";
    
    
    
    print $ofh "show cartoon, chain A \n";
    print $ofh "color red, chain A \n";
	if(defined $formustang){
        print $ofh "show cartoon, chain B \n";
        print $ofh "color green, chain B \n";

        print $ofh "show cartoon, chain C \n";
        print $ofh "color blue, chain C \n";

        print $ofh "show cartoon, chain D \n";
        print $ofh "color magenta, chain D \n";
	}
    
    print $ofh "#You can set the surface to be partially transparent. \n";
    print $ofh "set transparency=0.5 \n";

	#print $ofh "set sphere_scale, 0.25, (all) \n";
    
    my $ifh = util_read($infile);
	my $cnt = 0; 
    while(<$ifh>){
         next if(/^\s*$/);
         next if(/^\s*#/);
	     my (@l) = split ; 
		 my $color = shift @l ;
		 my $isligand = shift @l ;
		 my $nm  = "active$cnt"; $cnt++;

         _printActiveSite($ofh,$nm,$color,$isligand,\@l);
	}
    print $ofh "\n\n\n\n";
    print $ofh "alter ligand, vdw=0.5 \n";
    print $ofh "rebuild \n";
    print $ofh "set transparency=0.25 \n";
    
    
    print $ofh "#8. Rendering and output \n";
    print $ofh "bg_color white \n";
    print $ofh "ray \n" if($RAY);
    
}

sub _printActiveSite{
	my ($ofh,$nm,$color,$isligand,$l) = @_ ; 
	my @l = @{$l};
	my $str = join ",", @l ;
    print $ofh "\n\n\n\n";
    print $ofh "# Color the active site residue \n";
    #print $ofh "select $nm, (resi $str around 10 ) \n";
    print $ofh "select $nm, (chain A and resi $str ) \n";
    print $ofh "show sticks, $nm \n";
    print $ofh "color $color, $nm \n";
    #print $ofh "zoom $nm \n";

    
    print $ofh "\n\n\n\n";
	if($isligand){
         print $ofh "#7. Locate and display the bound formate ion in the active site. \n";
         print $ofh "select ligand, $nm around 2.5 and resn ZN \n";
         print $ofh "show spheres, ligand \n";
         print $ofh "color $color, ligand \n";
	}
}


sub util_PrintPymolResidue{
	my ($ofh,$which,$list1,$cnt,$color) = @_ ;
	if(!defined $list1){
		print STDERR "NO atoms \n";
		return ; 
	}
	my @list1 = @{$list1};
	$color = "blue" if(!defined $color);
	foreach my $atom (@list1){
		my $resnum = $atom->GetResNum();
		my $type = $atom->GetType();
		my $nm = "block_query$cnt"; 
	    print $ofh "select $nm, /$which//A/$resnum/$type \n";
	    print $ofh "color $color, $nm \n";
	    print $ofh "show spheres, $nm \n";
		$cnt++;
	}
	return $cnt ;
}

sub util_PrintPymolShell {
	my ($ofh,$pdb,$name) = @_ ;

	print $ofh "embed $name, pdb\n";
	my $ifh = util_read($pdb);
	while(<$ifh>){
		print $ofh $_ ;
	}
	print $ofh "embed end\n";
}



sub util_MakeMovieFromImages{
   my ($scriptname,@l) = @_ ; 
   my $ofh1 = util_write($scriptname);
   print $ofh1 "mencoder \\\n";
   foreach my $image (@l){
       print $ofh1 "\"mf://$image\"\\\n";
   }
   print $ofh1 "-mf fps=3 -o test.avi -ovc lavc -lavcopts vcodec=msmpeg4v2:vbitrate=800 \n";
}

sub PrintColorName{
	my ($ofh) = @_ ; 
    print $ofh "set_color red=   [1.00 , 0.00 , 0.00] \n";
    print $ofh "set_color mred=  [1.00 , 0.6 , 0.60] \n";
    print $ofh "set_color lred=  [1.00 , 0.3 , 0.30] \n";

	print $ofh "set_color green= [0.00 , 0.53 , 0.22] \n";
	print $ofh "set_color mgreen=[0.50 , 0.78 , 0.50] \n";
	print $ofh "set_color lgreen=[0.25 , 0.78 , 0.25] \n";
	print $ofh "set_color vgreen=[0.10 , 0.78 , 0.10] \n";

	print $ofh "set_color blue=  [0.02 , 0.50 , 0.72] \n";
	print $ofh "set_color mblue= [0.5  , 0.7  , 0.9 ] \n";
	print $ofh "set_color lblue= [0.86 , 1.00 , 1.00] \n";
	 

}

sub pymolin_getResultsLine{
    my ($in,$p1,$p2) = @_ ; 
    my $ifh = util_read($in);
    my @l ; 
	my ($a1,$a2);
    while(<$ifh>){
	    next if(/RESULT/);
		print $_ ;
		if(!defined $a1){
		    $a1 = $p1->ParseResultLine($_) ;
		    next ;
		}
		if(!defined $a2){
		    $a2 = $p2->ParseResultLine($_) ;
		     next;
		}
    }
    return ($a1,$a2);
}

sub pymolin_getResultsLineAll{
    my ($in,@pdbs) = @_ ; 
    my $ifh = util_read($in);
    my @l ; 
    while(<$ifh>){
	    next if(/RESULT/);
		my $p1 = shift @pdbs ;
		my $a1 = $p1->ParseResultLine($_) ;
		push @l, $a1 ;
    }
    return @l ;
}

sub pymolin_getResultsLineAllFromList{
    my ($list,$pdbs) = @_ ; 
	my @list = @{$list};
	my @pdbs = @{$pdbs};
	my @l ;
	while(@pdbs){
		my $p1 = shift @pdbs ;
		my $atoms = shift @list ;
		my $str = join " ", @{$atoms};
		print "$str \n";
		my $a1 = $p1->ParseResultLine($str) ;
		push @l, $a1 ;
    }
	die "@list"  if(@list);
    return @l ;
}


sub pymolin_AddAtomstoPymolin{
    my ($in,$p1,$newatoms,$ofh) = @_ ; 
    my $ifh = util_read($in);
	my $a1 ; 
    while(<$ifh>){
	    if(/RESULT/){
			print $ofh "$_";
			next ; 
		}
		if(!defined $a1){
		    $a1 = $p1->ParseResultLine($_) ;
            my @l = @{$a1}; 
			push @l,@{$newatoms};

	        foreach my $a (@l){
		        my $resnum = $a->GetResNum();
		        my $t = $a->GetType();
		        my ($res) = $p1->GetResidueIdx($resnum);
		        my ($name) = $res->GetName();
        
		        print $ofh  " $name/$resnum/$t ";
	        }
	print $ofh  "\n";
		}
		else{
			print $ofh "$_";
		}
    }


}

sub util_PrintPymolWithAllProteins{
    my ($ofh,$pdbnames,$atoms) = @_ ; 

	my @ids; 
	my $cnt = 0 ; 
	foreach my $p (@{$pdbnames}){
		 my $id = "topmatch_$cnt";
		 push @ids, $id ;
         util_PrintPymolShell($ofh,$p,$id);
		 $cnt++;
	}




    print $ofh "delete all \n";

	## some general commands
    print $ofh "set_color carbon= [0.00 , 0.53 , 0.22] \n";

	print $ofh "set sphere_scale, 0.25, (all) \n";

	foreach my $id (@ids){
		 my $nm = "PDB$id";
         print $ofh "load_embedded $id,name=$nm,state=1,discrete=0 \n";
	}

    #print $ofh "select query, PDBA  \n";
    #print $ofh "select target, PDBB  \n";
    print $ofh "bg_color white \n";
    #print $ofh "set specularA, 0 \n";
	my $N = @ids - 1;
	foreach my $idx (0..$N){
		 my $id = $ids[$idx];
		 my $color = $colors[$idx];
		 $color = "red" if(!defined $color);
         print $ofh "color $color, PDB$id \n";
	}
    print $ofh "hide all \n";
    print $ofh "show cartoon, all \n";

	$cnt = 0 ; 
	foreach my $idx (0..$N){
		 my $list1 = $atoms->[$idx];
		 my $id = $ids[$idx];
		 my $nm = "PDB$id";
		 print $ofh "\n\n";
		 my $color = $colors[$idx];
         $cnt = util_PrintPymolResidue($ofh,$nm,$list1,$cnt,$color);
	}

}
