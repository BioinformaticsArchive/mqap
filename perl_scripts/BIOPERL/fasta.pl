  #!/usr/bin/perl
  use Bio::Tools::Run::Alignment::StandAloneFasta;
  use Bio::SeqIO;
  use strict;
  my @arg=(
  'b' =>'15',
  'O' =>'resultfile',
  'H'=>'',
  'program'=>'fasta34'
  );

  my $factory=Bio::Tools::Run::Alignment::StandAloneFasta->new(@arg);
  $factory->ktup(1);

  $factory->library('p');

  #print result file name
  print $factory->O;




