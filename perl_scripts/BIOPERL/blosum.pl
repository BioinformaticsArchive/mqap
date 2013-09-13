use Bio::Ext::Align;
use Bio::Seq;
use Bio::AlignIO;
use strict;
&Bio::Ext::Align::change_max_BaseMatrix_kbytes(20000);
my $cm   = &Bio::Ext::Align::CompMat::read_Blast_file_CompMat("blosum62.bla");

