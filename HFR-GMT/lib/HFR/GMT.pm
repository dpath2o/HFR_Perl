package HFR::GMT;

use 5.006;
use strict;
use warnings;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Math;

our $VERSION = '0.1';

################################################################################
sub determine_projection {

    my $self = shift;

    my ($lonmin,$lonmax,$latmin,$latmax) = $self->{gmt}->{regions}->{current} =~ m#-R(\S+)\/(\S+)\/(\S+)\/(\S+)#;

    my $lonmean = ($lonmin+$lonmax)/2;

    my ($projection_scale,$scale_position);
    if ($self->HFR::ACORN::is_codar) {

        $projection_scale = '7.5c';
        $scale_position = '-D10c/-2c/20c/1.5ch';

    } elsif ($self->HFR::ACORN::is_wera_station) {

        $projection_scale = '12.5c';
        $scale_position = '-D10c/-2c/20c/1.5ch';

    } else {

        $projection_scale = '17.5c';
        $scale_position = '-D10c/-2c/20c/1.5ch';

    }

    $self->{gmt}->{figures}->{projection} = sprintf("-Jq%s/%s",$lonmean,$projection_scale);
    $self->{gmt}->{figures}->{scale_position} = sprintf("%s",$scale_position);

    return $self;

}
################################################################################
sub determine_page_orientation {

    my $self = shift;

    my ($lonmin,$lonmax,$latmin,$latmax) = $self->{gmt}->{regions}->{current} =~ m#-R(\S+)\/(\S+)\/(\S+)\/(\S+)#;

    my $londiff = abs($lonmax-$lonmin);
    my $latdiff = abs($latmax-$latmin);

    if ( $latdiff > $londiff ) {

        $self->{gmt}->{figures}->{page_orientation} = 'portrait';

    } else {

        $self->{gmt}->{figures}->{page_orientation} = 'landscape';

    }

    return $self;

}
################################################################################
sub define_region {

  my $self = shift;
  my $lons = $self->{grid}->{longitudes};
  my $lats = $self->{grid}->{latitudes};

  my ($lonmin,$lonmax,$latmin,$latmax);

  my $fudge = 0.2;

  if ( $lons->max >= 0 ) { $lonmax = $lons->max + $fudge; } else { $lonmax = $lons->max - $fudge; }
  if ( $lons->min >= 0 ) { $lonmin = $lons->min - $fudge; } else { $lonmin = $lons->min + $fudge; }
  if ( $lats->min >= 0 ) { $latmin = $lats->min - $fudge; } else { $latmin = $lats->min - $fudge; }
  if ( $lats->max >= 0 ) { $latmax = $lats->max - $fudge; } else { $latmax = $lats->max + $fudge; } 

  $self->{gmt}->{regions}->{current} = sprintf("-R%3.6f/%3.6f/%3.6f/%3.6f",$lonmin,$lonmax,$latmin,$latmax);

  return $self;

}
################################################################################
sub predefined_acorn_regions {

  my $self = shift;
  my $site = shift;

  if ( $site =~ /turq/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{turq}; }
  if ( $site =~ /rot/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{rot}; }
  if ( $site =~ /sag/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{sag}; }
  if ( $site =~ /bonc/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{bonc}; }
  if ( $site =~ /cof/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{cof}; }
  if ( $site =~ /cbg/ ) { $self->{gmt}->{regions}->{current} = $self->{gmt}->{regions}->{cbg}; }
 
  return $self;

}

__END__

=head1 NAME

=head1 SYNOPSIS

=head2 EXAMPLE

=head1 REQUIREMENTS

=over 6

=item L<Date::Parse>

=item L<Date::Calc>

=item L<PDL::Lite>

=item L<YAML::XS>

=back

=head1 METHODS

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

1; # End of HFR::ACORN
