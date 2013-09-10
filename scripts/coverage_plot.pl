#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use HFR::ACORN;
use HFR::ACORN::Coverages;
use HFR::ACORN::Gridding;
use HFR::ACORN::FileOps;
use HFR::GMT;
use PDL::Lite;
#use PDL::Char;

################################################################################
# GET USE INPUTS
my ($SN,$t0,$tN,$use_predefined_region,$verbose,$help);
my $result = GetOptions (
			 "sos=s"                       => \$SN,
			 "start=s"                     => \$t0,
			 "stop=s"                      => \$tN,
			 "use_predefined_region!"      => \$use_predefined_region,
			 "v|verbose=s"                 => \$verbose,
                         "h|help!"                     => \$help
                        );

# PRINT USAGE AND EXIT
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

################################################################################
# LOAD IN ACORN STRUCTURE
my $acorn = HFR::ACORN->new(
			    sos   => $SN,
			    start => $t0,
			    stop  => $tN
			   );
if (defined $verbose) { $acorn->{misc}->{verbose} = $verbose; }

################################################################################
# CONSTRUCT THE LIST OF FILES IN THE COVERAGE
print "\nConstructing list of files... \n" if ($acorn->{misc}->{verbose}>0);
$acorn->HFR::ACORN::FileOps::construct_file_list;

################################################################################
# GRIDDING
print "\nGridding ... \n" if ($acorn->{misc}->{verbose}>0);
$acorn->HFR::ACORN::Gridding::construct_grid_file;
$acorn->HFR::ACORN::Gridding::read_grid;

################################################################################
# COMPUTE COVERAGES (writes out data to file)
print "\nComputing coverages ... \n" if ($acorn->{misc}->{verbose}>0);
$acorn->HFR::ACORN::Coverages::compute_coverage;
if ($acorn->{coverages}->{data}->nelem<10) {
    pod2usage( {
                -message => 'HALT! NO COVERAGE DATA',
                -exitval => 1,
                -verbose => 0
               } );
}

################################################################################
# FIGURE PREPARATION
# FILES
$acorn->HFR::ACORN::Coverages::construct_figure_file;
my $cpt_file   = sprintf("%s/%s",$acorn->{local_server}->{directories}->{tmp},$acorn->{gmt}->{files}->{coverage_cpt});
my $landpoints = sprintf("%s/%s_landpoints.txt",$acorn->{local_server}->{directories}->{gmt},$acorn->{codenames}->{site});
my $landmarks  = sprintf("%s/%s_landmarks.txt",$acorn->{local_server}->{directories}->{gmt},$acorn->{codenames}->{site});

# DEFINE THE REGION
if ( defined $use_predefined_region or $acorn->{use_predefined_region} ) {

  $acorn->HFR::GMT::predefined_acorn_regions( $acorn->{codenames}->{site} );

} else {

  $acorn->HFR::GMT::define_region;

}

# PAGE ORIENTATION
$acorn->HFR::GMT::determine_page_orientation;

# PROJECTION
$acorn->HFR::GMT::determine_projection;

################################################################################
# CREATE FIGURE

my ($syscall);

# GMTSET
$syscall = sprintf("gmtset PS_PAGE_ORIENTATION %s ".
                   "PS_MEDIA %s ".
                   "FONT_ANNOT_PRIMARY %s ".
                   "FONT_ANNOT_SECONDARY %s",
                   $acorn->{gmt}->{figures}->{page_orientation},
                   $acorn->{gmt}->{figures}->{ps_media},
                   $acorn->{gmt}->{figures}->{font_annot_prime},
                   $acorn->{gmt}->{figures}->{font_annot_secnd});
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# MAKECPT
$syscall = sprintf("%s/makecpt -Crainbow -T0.01/1/0.1 > %s",
                   $acorn->{gmt}->{bin_directory},
                   $cpt_file);
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSBASEMAP
$syscall = sprintf("%s/psbasemap %s %s %s %s -K > %s",
                   $acorn->{gmt}->{bin_directory},,
                   $acorn->{gmt}->{figures}->{frame},
                   $acorn->{gmt}->{regions}->{current},
                   $acorn->{gmt}->{figures}->{projection},
                   $acorn->{gmt}->{figures}->{page_offset},
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSCOAST
$syscall = sprintf("%s/pscoast -R -J -Df -Gblack -Swhite -O -K >> %s",
                   $acorn->{gmt}->{bin_directory},
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSXY coverages
$syscall = sprintf("%s/psxy %s -R -J -C%s %s -O -K >> %s",
                   $acorn->{gmt}->{bin_directory},
                   $acorn->{coverages}->{files}->{full_path},
                   $cpt_file,
                   $acorn->{gmt}->{figures}->{circles},
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSXY landpoints
$syscall = sprintf("%s/psxy %s -Sa1c -Ggray -R -J -O -K >> %s",
                   $acorn->{gmt}->{bin_directory},
                   $landpoints,
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSTEXT landmarks
$syscall = sprintf("%s/pstext %s -Ggray -R -J -O -K >> %s",
                   $acorn->{gmt}->{bin_directory},
                   $landmarks,
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

# PSSCALE
$syscall = sprintf("%s/psscale -C%s %s -Ac -B0.1:Coverage:/:'1/100': -O -K >> %s",
                   $acorn->{gmt}->{bin_directory},
                   $cpt_file,
                   $acorn->{gmt}->{figures}->{scale_position},
                   $acorn->{coverages}->{files}->{figure}
                  );
print "Making the following system call:\n".$syscall."\n\n" if ($acorn->{misc}->{verbose}>1);
system($syscall);

printf("Coverage map file created: %s\n\n",$acorn->{coverages}->{files}->{figure}) if ($acorn->{misc}->{verbose}>0);

__END__

=head1 NAME

coverage_plot.pl

=head1 SYNOPSIS

This script will plot a map of HF radar radial or vector coverage (distribution) as a function of time

coverage_plot.pl --sos=guilderton --start='14 Sep 2012' --stop='18 Sep 2012' [-verbose|v=<LEVEL>]

Coverages will be computed from the start time to the stop time for the given station or site.

Requires HFR YAML configuration file. See L<HFR::YAML>

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

21 Sep. 2012

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Daniel Patrick Atwater

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

