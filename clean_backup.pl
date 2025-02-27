#!/usr/bin/perl
# -*- mode: cperl; coding: utf-8; -*-
# /data/code/scripts/clean_backup.pl
# created at 26. 02. 2025 by Benjamin Walkenhorst
# (c) 2025 Benjamin Walkenhorst <krylon@gmx.net>
# Time-stamp: <2025-02-26 20:15:22 krylon>
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

# I am using borg to backup my stuff on a couple of computers, and this script
# aims to clean up old backups.
# The idea is - roughly speaking - to keep around the following backups:
# - daily for the past 2 weeks
# - weekly for the past 6 weeks
# - monthly for the past 6 months (maybe 12?)
#
# Conveniently, my backup script uses the date to name the backups, so this
# shouldn't be too hard (*cue manic laughter*).

use strict;
use warnings;
use diagnostics;
use utf8;
use feature qw(say defer);

use Carp;
use English '-no_match_vars';

use Getopt::Long;
use Readonly;

no warnings 'experimental::defer';

## Constants won't; variables aren't

Readonly my $CMD => 'borg';

my $path = '';
my $password = '';
my $action = '';

## "main"

GetOptions(
           'path=s' => \$path,
           'password=s' => \$password,
           'action=s' => \$action,
          ) or die "Error in command line arguments: $!";

if ($password ne '') {
  $ENV{BORG_PASSPHRASE} = $password;
}

if ($path ne '') {
  $ENV{BORG_REPO} = $path;
}

$action = lc $action;

say "Repo: $ENV{BORG_REPO} / Password: $ENV{BORG_PASSPHRASE}";

if ($action eq 'list') {
  my @archives = list_backups();

  printf 'Found %d archives:', scalar(@archives);
  say '';

  foreach my $archive (sort @archives) {
    say $archive;
  }
}

## Subroutines

sub list_backups {
  my @backups = ();

  open(my $proc, '-|', "$CMD list")
    or die "Cannot run '$CMD list'";

  defer { close $proc or die "Failed to close proc handle: $!"; }

  for my $line (<$proc>) {
    my ($archive) = $line =~ /^(\S+)/xms;
    push @backups, $archive;
  }

  return @backups;
} # sub list_backups


# Local Variables: #
# compile-command: "perl -c /data/code/scripts/clean_backup.pl" #
# End: #
