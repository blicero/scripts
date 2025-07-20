#!/usr/bin/perl
# -*- mode: cperl; coding: utf-8; -*-
# /home/krylon/OneDrive/Dokumente/astrocast_rename.pl
# created at 18. 07. 2025 by Benjamin Walkenhorst
# (c) 2025 Benjamin Walkenhorst <krylon@gmx.net>
# Time-stamp: <2025-07-20 00:39:26 krylon>
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
use feature qw(say);

use Carp;
use English '-no_match_vars';
use Readonly;

Readonly my $FOLDER => '/home/krylon/Audiobooks/Astronomy Cast';
Readonly my $EPISODE_LIST => '/home/krylon/OneDrive/Dokumente/AstronomyCast_Episodes.csv';
Readonly my $OPUSTAGS => '/usr/bin/opustags';

$| = 1;

sub tag_file {
  my ($path, $year, $episode, $title) = @_;

  my @cmd = (
             '--in-place',
             '--add',
             sprintf('ARTIST=%s', 'Fraser Cain and Dr. Pamela Gay'),
             '--add',
             sprintf('ALBUM=%s', 'AstronomyCast'),
             '--add',
             sprintf('TITLE=%s', $title),
             '--add',
             sprintf('DATE=%d', $year),
             '--add',
             sprintf('TRACK=%d', $episode),
             $path,
            );

  system $OPUSTAGS, @cmd;
  # say join(' ', @cmd);
} # sub tag_file

open(my $csv, '<', $EPISODE_LIST)
  or die "Cannot open $EPISODE_LIST: $OS_ERROR";

my %episodes = ();

while (my $line = <$csv>) {
  chomp $line;
  my @pieces = split /;/, $line;

  if ($pieces[0] =~ m{(\d+)/(\d+)/(\d+)}xms) {
    my ($month, $day, $year) = ($1, $2, $3);
    my $date = sprintf '%04d-%02d-%02d',
      $year,
      $month,
      $day;

    next if $pieces[1] !~ /\d+/xms;

    $episodes{$date} = {
                        episode => int($pieces[1]),
                        title => $pieces[2],
                       };
  }
}

close $csv;

chdir $FOLDER;

opendir(my $dir, $FOLDER)
  or die "Cannot open $FOLDER: $OS_ERROR";

while (my $file = readdir $dir) {
  if ($file =~ /^[.]/xmsi) {
    next;
  }

  if ($file =~ /^astrocast-(\d{2})(\d{2})(\d{2})b?[.](opus)$/xmsi) {
    my ($year, $month, $day, $suffix) = (int($1) + 2000, int($2), int($3), $4);
    my $date = sprintf('%04d-%02d-%02d',
                       $year,
                       $month,
                       $day);

    if (exists $episodes{$date}) {
      my $new_name = sprintf('AstronomyCast - %03d - %s.%s',
                             $episodes{$date}->{episode},
                             $episodes{$date}->{title},
                             $suffix);

      rename $file, $new_name
        or die "Cannot rename $file to $new_name: $OS_ERROR";
      printf 'Rename %-60s => %s' . "\n",
        $file,
        $new_name;

      tag_file($new_name,
               $year,
               $episodes{$date}->{episode},
               $episodes{$date}->{title});
    }
  } elsif ($file =~ /^(\d{4}-\d{2}-\d{2})-ep\s+(\d+)\s+(.*)[.](\w+)$/xmsi) {
    # In this case, we can extract all the information we need
    # from the filename itself.
    my ($date, $episode, $title, $suffix) = ($1, $2, $3, $4);

    my $new_name = sprintf 'AstronomyCast - %03d - %s.%s',
      $episode,
      $title,
      $suffix;

    printf 'Rename %-60s => %s' . "\n",
      $file,
      $new_name;
    rename $file, $new_name
      or die "Cannot rename $file to $new_name: $OS_ERROR";

    my $year = substr $date, 0, 4;

    tag_file($new_name,
             $year,
             $episode,
             $title);
  } else {
    say "I don't know what to do with $file";
  }
}

closedir $dir;

# Local Variables: #
# compile-command: "perl -c /home/krylon/OneDrive/Dokumente/astrocast_rename.pl" #
# End: #
