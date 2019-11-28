#!/usr/bin/perl
#Copyright 2016  Tsinghua University (Author: Dong Wang).  Apache 2.0.
#conver morpheme to word
use strict;
use List::Util qw( max min );


sub MorphToWord{
    my($s) = @_;    
    my @morph = split(/ /, $s);
    my $word ="";
    my $priorM = "";
    while(@morph) {
        my $h = shift(@morph);         
        if(index($h,"_") eq 0)
        {           
              $h=~ s/_//g;
              $word = $word . $h;           
        }
        else
        {
           my $indx = index $priorM,"_";
           if($indx eq length($priorM)-1)   # for prefix;  
          {
               $word =~ s/_$//g;  #remove the previous prefix's slash.
               $word = $word  . $h;
          }
           else { $word = $word . " " . $h;}         
   
       }
       $priorM = $h;
    }
   return $word;
}

use strict;
binmode STDOUT, ":utf8";
open MORPH, "<:utf8", $ARGV[0];
open WORD, ">:utf8", $ARGV[1];

my $reflen = 0;
my($ref, $test);
while($ref = <MORPH>) 
{
    chomp $ref; chomp $test;
  

# ////////////////////////////////////////
    my $test = MorphToWord($ref);
# ////////////////////////////////////////
    $test =~ s/\s+/ /g; $test =~ s/\s*$//g; $test =~ s/^\s*//g;   $test =~ s/-//g; 
   
    print WORD  "$test\n" ;
    $reflen++;
   
}

close WORD;
close MORPH;
printf "morphemes are converted into words, processed lines: $reflen\n";


