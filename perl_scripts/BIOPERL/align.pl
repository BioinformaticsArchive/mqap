   use Bio::Tools::pSW;
    use Bio::AlignIO;
    my $factory = new Bio::Tools::pSW( '-matrix' => 'blosum62.bla',
				       '-gap' => 12,
				       '-ext' => 2,
				       );

    #use the factory to make some output
	$seq1 = get_sequence('swiss',"ROA1_HUMAN");
	$seq2 = get_sequence('swiss',"ROA1_MOUSE");


    $factory->align_and_show($seq1,$seq2,STDOUT);

    # make a Bio::SimpleAlign and do something with it

    my $aln = $factory->pairwise_alignment($seq1,$seq2);
    my $alnout = new Bio::AlignIO(-format => 'msf',
				  -fh     => \*STDOUT);

    $alnout->write_aln($aln);

