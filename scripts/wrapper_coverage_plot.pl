#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use PDL::Lite;
use HFR::ACORN;

# get inputs
my ($SN,$t0,$tN,$dt,$help);
my $result = GetOptions (
			 "sos=s"   => \$SN,
			 "start=s" => \$t0,
			 "stop=s"  => \$tN,
			 "dt=s"    => \$dt,
			 "help|h"  => \$help
			);
# usage and exit
if ($help) {
    pod2usage( {
                -message => 'Printing usage and exiting',
                -exitval => 0
               } );
}
unless (defined $SN) {
    pod2usage( {
                -message => 'Station or Site not given!',
                -exitval => 1,
                -verbose => 0
               } );
}
unless (defined $t0) {
    pod2usage( {
                -message => 'Start time not given!',
                -exitval => 1,
                -verbose => 0
               } );
}
unless (defined $tN) {
    pod2usage( {
                -message => 'Stop time not given!',
                -exitval => 1,
                -verbose => 0
               } );
}

# put the dates into unix format
my $acorn = HFR::ACORN->new( start=>$t0 , stop=>$tN );
$acorn->HFR::ACORN::determine_datetime;
$dt = $acorn->{coverages}->{dt} unless (defined $dt);

# put $dt from days into seconds
$dt = 60*60*24*$dt;

# make sure the dates are logical with regard to $dt
$tN = $acorn->{time}->{stop}->sclr;
$t0 = $acorn->{time}->{start}->sclr;
unless ( $tN >= ($t0+$dt) ) {
    my $exit_msg = sprintf("\nHALT!\nStop time (%d) is not greater than or equal to start time (%d) plus delta time (%d)\n\n",$tN,$t0,$dt);
    pod2usage( {
                -message => $exit_msg,
                -exitval => 2,
                -verbose => 0
               } );
}

# MAIN LOOP
while ( $t0 < $tN ) {

    my ($t0_str,$tN_str) = HFR::ACORN::define_datestr_function( $t0 , ($t0+$dt) );
    my $sysstr = sprintf('perl %s/coverage_plot.pl --sos=%s --start=%s --stop=%s',
                         $acorn->{local_server}->{directories}->{perl_bin},
                         $SN,
                         $t0_str,
                         $tN_str
                        );
    print "\n\n\n\nISSUING COMMAND:\n$sysstr\n\n";
    system($sysstr);
    $t0+=$dt;

}

__END__

=head1 NAME

wrapper_coverage_plot.pl

=head1 SYNOPSIS

This script will call coverage_plot.pl in loop that starts at start time and goes to stop time counting by the delta time.

wrapper_coverage_plot.pl --sos=guilderton --start='14 Sep 2012' --stop='14 Sep B<2013>' [-dt=<days>] [-verbose|v=<LEVEL>]

Possibly the SYNOPSIS of coverage_plot.pl will help you understand more.

=head2 REQUIRED INPUTS

There are three required inputs shown in the synopsis. They are:

=over 4

=item B<sos>

Station or site name. This can be a codename or plain name of a station or site.

=item B<start>

The beginning/start time, has to be parse-able by Date::Parse.

=item B<stop>

The ending/stop time, has to be parse-able by Date::Parse.

=back

=head2 OPTIONAL INPUTS

=over 4

=item B<dt=DAYS>

Default 7 days. Enter any integer greater than 0 and less then difference between start time and stop.

=item B<v|verbose=LEVEL>

Print out different levels of information to STDOUT. 'LEVEL' is an integer greater than 0.

=item B<h|help>

Print SYNOPSIS and exit

=back

=head1 PERL PACKAGES

=over 4

=item Getopt::Long

See L<Getopt::Long>

=item Pod::Usage

See L<Pod::Usage>

=item HFR::ACORN

See L<HFR::ACORN>

=item HFR::ACORN::Coverages

See L<HFR::ACORN::Coverages>

=item HFR::ACORN::Gridding

See L<HFR::ACORN::Gridding>

=item HFR::ACORN::FileOps

See L<HFR::ACORN::FileOps>

=item HFR::GMT

See L<HFR::GMT>

=item PDL::Lite

See L<PDL::Lite>

=back

=head2 AUTHOR

Daniel Atwater, C<danielpath2@gmail.com>

=head2 Version

=over 4

=item 0.1

25 Sep. 2012

=back

=cut

