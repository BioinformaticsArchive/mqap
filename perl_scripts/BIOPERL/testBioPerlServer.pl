use Bio::Perl;

  # this script will only work with an internet connection
  # on the computer it is run on
  $seq_object =get_sequence('genbank',"NM_173283");
#print "$seq_object";
  write_sequence(">ILGF1.gb",'genbank',$seq_object);
