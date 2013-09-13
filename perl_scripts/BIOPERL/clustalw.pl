use Bio::Tools::Run::Alignment::Clustalw;
@params = ('ktuple' => 2, 'matrix' => 'BLOSUM');
$factory = Bio::Tools::Run::Alignment::Clustalw->new(@params);
$ktuple = 3;
$factory->ktuple($ktuple);  # change the parameter before executing
$seq_object = get_sequence('swiss',"ROA1_HUMAN");
$seq_object1 = get_sequence('swiss',"ROA1_MOUSE");
$seq_object2 = get_sequence('swiss',"P08854");

push @seq_array,$seq_object ;
push @seq_array,$seq_object1 ;
push @seq_array,$seq_object2 ;

$seq_array_ref = \@seq_array;
		        # where @seq_array is an array of Bio::Seq objects
$aln = $factory->align($seq_array_ref);
