#!/usr/bin/perl
# -*- mode: cperl; coding: utf-8; -*-
# /data/code/scripts/blabla.pl
# created at 26. 04. 2026 by Benjamin Walkenhorst
# (c) 2026 Benjamin Walkenhorst <krylon@gmx.net>
# Time-stamp: <2026-04-28 12:17:10 krylon>
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY BENJAMIN WALKENHORST ``AS IS'' AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#  ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
#  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
#  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#  SUCH DAMAGE.

use strict;
use warnings;
use diagnostics;
use utf8;
use feature qw(say unicode_strings);

use Carp;
use English '-no_match_vars';
use File::Slurp;
use Getopt::Long;
use IO::Handle;
use Readonly;

Readonly my $PDF2TXT => 'pdf2txt';

my $training_file;
my $out_file;
my $word_cnt = 250;
my $show_help = 0;
my $verbose = 0;

STDOUT->autoflush(1);

$SIG{INT} = sub { say 'I hate it when you interrupt me!'; exit 0; };

GetOptions(
           'c|count=i' => \$word_cnt,
           't|training=s' => \$training_file,
           'o|output=s' => \$out_file,
           'v|verbose!' => \$verbose,
           'h|help' => \$show_help,
          );

if ($show_help) {
  say <<"HELP";
Usage: $0 [-c|--cnt=<n>] [-t|--training=<s>] [-v|--verbose] [-h|--help]

--cnt=<n> / -c <n>      Number of words to print
--training=<s> / -t <s> File to train from
--output=<s> / -o <s>   File to write output to
--verbose / -v          Emit additional messages to show what is happening
--help / -h             Display this help message and exit
HELP

  exit 0;
}

my $model = read_training_file($training_file);

say "Trained model, generating $word_cnt words of text." if $verbose;

my $output = generate_text($model, $word_cnt);

if ($verbose) {
  my $len = length $output;
  say "Generated $len characters of text.";
}

open(my $out, '>:encoding(UTF-8)', $out_file)
  or croak "Cannot open $out_file: $OS_ERROR";

$out->write($output);

close $out;

say "Toodles";

########################################################################
### Subroutines ########################################################
########################################################################

sub read_training_file {
  my ($path) = @_;

  if (not -f $path) {
    croak "Training file $path does not exist";
  } elsif ($path !~ /[.]txt$/xmsi) {
    croak "Training file $path is not a text file";
  } else {
    say "Training from $path" if $verbose;
  }

  my $text = read_file($path, binmode => ':utf8');

  if ($verbose) {
    my $length = length($text);
    say "Training file has $length characters.";
  }

  my %predict = ();
  my @word_list = split qr{\W+}l, $text;
  my $prev = shift @word_list;
  my $curr = shift @word_list;
  my $cnt = 0;

  foreach my $word (@word_list) {
    next if $word =~ m{\d};

    $cnt++;
    $prev = $curr;
    $curr = $word;
    $predict{$prev}{$curr} += 1;
  }

  return {
          words => \@word_list,
          predict => \%predict,
          cnt => $cnt,
         };
} # read_training_file

sub generate_text {
  my ($model, $cnt) = @_;
  my $i = 0;
  my @result = ();

  if (0 == scalar keys %{$model->{predict}}) {
    die 'Model has not been trained, it would appear.';
  }

 START:
  my $next_word = $model->{words}->[int(rand($cnt))];

  # say "Starting with $next_word" if $verbose;

  foreach my $idx ($i .. $cnt) {
    goto START unless defined $next_word;

    say "idx = $idx, next_word = $next_word" if $verbose;

    if ($next_word =~ /^[[:upper:]]/xms && (0 == int(rand(10)))) {
      push @result, '.';
    }

    if (0 == int(rand(25))) {
      push @result, "\n";
    }

    push @result, $next_word;
  } continue {
    my @next_words = keys %{ $model->{$next_word} };
    $next_word = $next_words[int(rand(scalar @next_words))];
    $i++;

    say "Generated $i words so far." if $verbose;
  }

  my $txt = join ' ', @result;
  $txt =~ s/\s+[.]/./xmsg;

  return $txt;
} # generate_text

# Local Variables: #
# compile-command: "perl -c /data/code/scripts/blabla.pl" #
# End: #
