#!/usr/bin/env perl
#
# Convert character assembler to SVG
#

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

# Create a map of all characters
my $map;

# Where to draw the character
my $x_offset;
my $y_offset = 0;

if ($ARGV[0] eq '-m') {
	$map = 1;
	shift;
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

# Draw the accumulated polyline
sub draw_polyline
{
	if ($#polyline > 1) {
		if ($map) {
			# Shift the character into its position
			for (my $i = 0; $i <= $#polyline; $i += 2) {
				$polyline[$i] += $x_offset;
				$polyline[$i + 1] += $y_offset;
			}
		}

		my $polystring = join(' ', @polyline);
		print $out qq{\t<polyline points="$polystring" stroke="black" stroke-width="40" stroke-linecap="round" fill="none" stroke-linejoin="round" />\n};
	}
	@polyline = ($ox, $oy);
}

$ox = charmap('a');
$oy = charmap('n');

while (<>) {
	chop;
	if (/^:(.*)/) {
		my $name = $1;
		if ($map) {
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
		if (!$map) {
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

if ($map) {
	print $out "</svg>\n";
	close($out);
}
