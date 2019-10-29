#!/usr/bin/env perl
#
# Convert character assembler to SVG
#

my $out;
my $draw;
my $ox;
my $oy;

# Map a character a-n into a value 0-1000
sub charmap
{
	my ($c) = @_;
	my $v = ord($c) - ord('a');
	return sprintf('%.0f', $v / 16 * 800 + 100);
}

$ox = charmap('a');
$oy = charmap('n');

while (<>) {
	if (/^:c(.)/) {
		open($out, '>', "c$1.svg") || die;
		print $out qq{<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">\n};

	} elsif (/^x/) {
		$draw = 0;
	} elsif (/^v/) {
		$draw = 1;
	} elsif (/^r/) {
		print $out "</svg>\n";
		close($out);
		$ox = charmap('a');
		$oy = charmap('m');
	} elsif (/^([a-n])([a-n])$/) {
		my $y = charmap($1);
		my $x = charmap($2);
		if ($draw) {
			print $out qq{\t<line x1="$ox" y1="$oy" x2="$x" y2="$y" stroke="black" stroke-width="40" />\n};
		}
		$ox = $x;
		$oy = $y;
	} elsif (/^$/) {
		next;
	} else {
		print STDERR "$ARGV($.): Unknown command $_";
	}
}
