#!/usr/bin/perl -w


use strict;

sub MakeString()
  {
  my($string) = "";
  my($i);
  foreach $i (32..126)
    {
    $string .= chr($i) unless ($i == 34);
    }
  return($string);
  }

sub MakePage()
  {
  print "Content-type: text/html\n\n";
  print "<html><head><title>Hello World Form</title></head><body>\n";

  print "<center><big><big><big><strong>\n";
  print "Hello World Form<p>\n";
  print "</strong></big></big></big>\n";

  print "<FORM ACTION=\"./stdin.cgi\" METHOD=\"POST\">\n";
  print "The Field...<br>\n";
  print "<input type=\"text\" name=\"TXhelloField\" size=\"100\" \n";
  print "value=\"" . MakeString() . "\">\n";
  print "<INPUT type=\"submit\" name=\"BXsub\" value=\"Submit\">\n";
  print "</form>"; 

  print "</body></html>\n"; 
  }

MakePage();
