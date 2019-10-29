#!/usr/bin/env perl
#
# Convert character assembler to SVG
#

use strict;
use warnings;

my $out;
my $draw;
my $ox;
my $oy;
my $polyline = '';

# Map a character a-n into a value 0-1000
sub charmap
{
	my ($c) = @_;
	my $v = ord($c) - ord('a');
	return sprintf('%.0f', $v / 16 * 800 + 100);
}

# Draw the accumulated polyline
sub draw_polyline
{
	print $out qq{\t<polyline points="$polyline" stroke="black" stroke-width="40" stroke-linecap="round" fill="none" stroke-linejoin="round" />\n};
	$polyline = "$ox $oy";
}

$ox = charmap('a');
$oy = charmap('n');

while (<>) {
	if (/^:c(.)/) {
		open($out, '>', "c$1.svg") || die;
		print $out qq{<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">\n};

	} elsif (/^x/) {
		$draw = 0;
		draw_polyline();
	} elsif (/^v/) {
		$draw = 1;
		draw_polyline();
	} elsif (/^r/) {
		draw_polyline();
		print $out "</svg>\n";
		close($out);
		$ox = charmap('a');
		$oy = charmap('m');
	} elsif (/^([a-n])([a-n])$/) {
		my $y = charmap($1);
		my $x = charmap($2);
		if ($draw) {
			$polyline .= " $x $y";
		}
		$ox = $x;
		$oy = $y;
	} elsif (/^$/) {
		next;
	} else {
		print STDERR "$ARGV($.): Unknown command $_";
	}
}
