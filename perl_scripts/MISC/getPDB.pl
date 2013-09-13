
  use WWW::PDB qw(:all);

  # set directory for caching downloads
  WWW::PDB->cache('/tmp/bar');
  
  my $fh = get_structure("1A0J");
  print while <$fh>;
  
  # my @pdbids = WWW::PDB->keyword_query('carbonic anhydrase');
  # for(@pdbids) {
      # my $citation = WWW::PDB->get_primary_citation_title($_),
      # my @chains   = WWW::PDB->get_chains($_);
      # printf("%s\t%s\t[%s]\n", $_, $citation, join(', ', @chains));
  # }
# 
  # my $seq = q(
      # VLSPADKTNVKAAWGKVGAHAGEYGAEALERMFLSFPTTK
      # TYFPHFDLSHGSAQVKGHGKKVADALTAVAHVDDMPNAL
  # );
  # print WWW::PDB->blast($seq, 10.0, 'BLOSUM62', 'HTML');
