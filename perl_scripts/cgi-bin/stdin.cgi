#!/usr/bin/perl
print "Content-type: text/html\n\n";
print "Output of form. Copy next line into clipboard:<P>\n";
while(<STDIN>)
  {
  chomp($_);
  print "$_<br>\n";
  }
print "Copy previous line into clipboard<P>\n";
