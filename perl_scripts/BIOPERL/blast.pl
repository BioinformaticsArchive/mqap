#! /usr/bin/perl
use warnings;
use strict;

use Bio::SeqIO;
use Bio::Seq;
use Bio::Tools::Run::StandAloneBlast;
#use Bio::Tools::Blast ;
use Bio::Tools::Blast;


my $seqio_obj;
my $seq_obj;
my @params;
my $blast_obj;
my $result_obj;
my $report_obj;

# $seqio_obj = Bio::SeqIO->new(-file => 'seq.fasta',
# -format => 'fasta' );
# # to wrtie the sequence to afasta file
# $seq_obj = $seqio_obj->next_seq;
# #print $seq_obj->seq,"\n";
# @params = (program => 'blastp',
# database => 'pdbaa',
# outfile => 'blast1.out');
# $blast_obj = Bio::Tools::Run::StandAloneBlast->new(@params);
# $report_obj = $blast_obj->blastall($seq_obj);
# $result_obj = $report_obj->next_result;

my $seq = "seq.fasta";
    my %runParam = (
                  -method   => 'remote',
                  -prog     => 'blastp',
                  -database => 'swissprot',
                  -seqs     => [ $seq ],  # Bio::Seq.pm objects.
                  );

my     $blastObj = Bio::Tools::Blast->new( -run     => \%runParam,
                                        -parse   => 1,
                                        -signif  => '1e-10',
                                        -strict  => 1,
                                        );

print $result_obj->num_hits; 
