use Bio::Perl;
use Bio::DB::SwissProt;
use Bio::Tools::Run::Alignment::Clustalw;

my    @params = ('ktuple' => 2, 'matrix' => 'BLOSUM');
my    $factory = Bio::Tools::Run::Alignment::Clustalw->new(@params);
my    $ktuple = 3;
my    $factory->ktuple($ktuple);  # change the parameter before executing


sub GetSequence{
	my ($arr,$pdbid,$swissid,$write)= @_ ;
    my $seq_object = get_sequence('swiss',"$swissid");
    push @{$arr}, $seq_object ;
	if(defined $write){
          write_sequence(">$pdbid.$swissid.fasta",'fasta',$seq_object);
	}
}


$annotation = $seq_object->annotation();
my @structures = ();
foreach my $link ( $annotation->get_Annotations('dblink') ) {
if ($link->database() eq 'PDB') {
	 push (@structures, $link->primary_id());
   }
}
print "\nPDB Structures: ", join (" ", @structures), "\n";


my @seq_array  = ();

my $seqin = Bio::SeqIO->new ( -file   => 'roa1.fasta',
                              -format => 'fasta');
my $seq3 = $seqin->next_seq();


#push @seq_array, $seq_object ;
push @seq_array, $seq_object1 ;
push @seq_array, $seq3 ;

write_sequence(">roa1.fasta",'fasta',$seq_object);

		$seq_array_ref = \@seq_array;
		$aln = $factory->align($seq_array_ref);
