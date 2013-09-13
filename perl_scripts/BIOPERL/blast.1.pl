$seq_object = get_sequence('swissprot',"ROA1_HUMAN");
 uses the default database - nr in this case
 $blast_result = blast_sequence($seq);
 write_blast(">roa1.blast",$blast_report);
 [tisdall]$ perl tut2.pl

