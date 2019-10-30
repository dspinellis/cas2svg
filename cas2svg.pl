#!/usr/bin/env perl
#
# Convert Graphic 2 character assembly to SVG
#
# Copyright 2019 Diomidis Spinellis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;
use warnings;
use Getopt::Std;

# Create a map of all characters
our($opt_m);

# Stroke width
our($opt_w) = 60;

getopts('mw:');

use strict;
use warnings;

# Output file
my $out;

# True if currently drawing
my $draw;

my $ox;
my $oy;

# Accumulated polyline
my @polyline;

# Movement unit
my $unit = 50;
# Size of a complete character cell
my $cell_size = 1024;

# Where to draw the character
my $x_offset;
my $y_offset = 0;

if ($opt_m) {
	open($out, '>', "build/all.svg") || die;
	print $out '<svg viewBox="0 0 ', $cell_size * 8, ' ',
		$cell_size * 16, qq{" xmlns="http://www.w3.org/2000/svg">\n};
}

# Map a character a-n into a value 0-1000
sub charmap
{
	my ($c) = @_;
	my $v = ord($c) - ord('a');
	return sprintf('%.0f', $v * $unit + 100);
}

sub sign
{
	my ($a) = @_;
	if ($a == 0) {
		return 0;
	} elsif ($a < 0) {
		return -1;
	} else {
		return 1;
	}
}

# Draw the accumulated polyline
sub draw_polyline
{
	if ($#polyline > 1) {
		if ($opt_m) {
			# Shift the character into its position
			for (my $i = 0; $i <= $#polyline; $i += 2) {
				$polyline[$i] += $x_offset;
				$polyline[$i + 1] += $y_offset;
			}
		}
		for (my $i = 0; $i < 2; $i++) {
			$polyline[$#polyline - $i] -= sign($polyline[$#polyline - $i] - $polyline[$#polyline - 2 - $i]) * $unit;
		}

		my $polystring = join(' ', @polyline);
		print $out qq{\t<polyline points="$polystring" stroke="black" stroke-width="$opt_w" stroke-linecap="round" fill="none" stroke-linejoin="round" />\n};
	}
	@polyline = ($ox, $oy);
}

$ox = charmap('a');
$oy = charmap('n');

while (<>) {
	chop;
	if (/^:(.*)/) {
		my $name = $1;
		if ($opt_m) {
			if (defined($x_offset)) {
				$x_offset += $cell_size;
			} else {
				$x_offset = 0;
			}
			if ($x_offset > $cell_size * 8) {
				$x_offset = 0;
				$y_offset += $cell_size;
			}
		} else {
			open($out, '>', "build/$name.svg") || die;
			print $out qq{<svg viewBox="0 0 $cell_size $cell_size" xmlns="http://www.w3.org/2000/svg">\n};
		}
		print $out "<!-- Character $name -->\n";
	} elsif (/^x/) {
		print $out "<!-- x (pen up) -->\n";
		$draw = 0;
		draw_polyline();
	} elsif (/^v/) {
		print $out "<!-- v (pen down) -->\n";
		$draw = 1;
		draw_polyline();
	} elsif (/^r/) {
		draw_polyline();
		if (!$opt_m) {
			print $out "</svg>\n";
			close($out);
		}
		$ox = charmap('a');
		$oy = charmap('n');
	} elsif (/^([a-p])([a-n])$/) {
		my $y = charmap($1);
		my $x = charmap($2);
		print $out "<!-- moveto $1, $2 ($x, $y) -->\n";
		if ($draw) {
			push(@polyline, $x, $y);
		}
		$ox = $x;
		$oy = $y;
	} elsif (/^$/) {
		next;
	} else {
		print STDERR "$ARGV($.): Unknown command $_\n";
	}
}

if ($opt_m) {
	print $out "</svg>\n";
	close($out);
}
