package HFR::ACORN::Gridding;

use 5.006;
use strict;
use warnings;
use PDL::Lite;
use PDL::IO::Misc;
use PDL::NiceSlice;
use PDL::NetCDF;
use PDL::Char;
use HFR::ACORN;

################################################################################
sub construct_grid_file {

  my $self = shift;

  if ( $self->HFR::ACORN::is_site_seasonde ) {

    $self->{grid}->{files}->{primary} = sprintf('%s/%s/combine_%s.grd',$self->{local_server}->{directories}->{configs},$self->{codenames}->{site},$self->{codenames}->{site});

  } elsif ( $self->HFR::ACORN::is_wera ) {

    $self->{grid}->{files}->{primary} = sprintf('%s/%s/%s.grid',$self->{local_server}->{directories}->{configs},$self->{codenames}->{site},$self->{codenames}->{site});

  }

  printf("Grid file being used: %s\n",$self->{grid}->{files}->{primary}) if ($self->{misc}->{verbose}>=2);

  return $self;

}
################################################################################
sub read_wera_grid {

  my $self = shift;

  printf("Attempting to load grid file: %s\n",$self->{grid}->{files}->{primary});

  ($self->{grid}->{xi},$self->{grid}->{yi},$self->{grid}->{longitudes},$self->{grid}->{latitudes}) = rcols $self->{grid}->{files}->{primary}, 0,1,2,3, { EXCLUDE => '/^\%/' };

  printf("Grid file load\n") if ($self->{misc}->{verbose}>=3);

  return $self;

}
################################################################################
sub read_seasonde_site_grid {

  my $self = shift;

  printf("Attempting to load grid file: %s\n",$self->{grid}->{files}->{primary});

  ($self->{grid}->{xi},$self->{grid}->{yi},$self->{grid}->{longitudes},$self->{grid}->{latitudes}) = rcols $self->{grid}->{files}->{primary}, 6,7,3,4, { LINES => '26:-1' };

  printf("Grid file load\n") if ($self->{misc}->{verbose}>=3);

  return $self;

}
################################################################################
# use GMT 'project' function to compute lon/lat at each range step from a
# radial file
sub construct_seasonde_radial_grid {

  my $self   = shift;
  my $ncfile = shift;

  my $lonG = pdl;
  my $latG = pdl;

  printf ("Attempting to build radial grid from SeaSonde radial file: %s\n\n",$ncfile) if ($self->{misc}->{verbose}>0);

  my $nc = PDL::NetCDF->new( $ncfile );

  # pull out the origin (receive antenna location)
  my $lon0 = $nc->getatt( 'seasonde_Origin_Longitude', sprintf('seasonde_Header_%s',uc($self->{codenames}->{sos})) )->sclr;
  my $lat0 = $nc->getatt( 'seasonde_Origin_Latitude' , sprintf('seasonde_Header_%s',uc($self->{codenames}->{sos})) )->sclr;

  # pull out the range information 
  my $drng  = $nc->getatt( 'seasonde_Range_Resolution', sprintf('seasonde_Header_%s',uc($self->{codenames}->{sos})) )->sclr;
  my $rngN  = $nc->getatt( 'seasonde_Range_Limit', sprintf('seasonde_Header_%s',uc($self->{codenames}->{sos})) )->sclr;
  my $rng_m = $rngN*$drng; # maximum range in meters

  # pull out the angular resolution as well as bearing and put into linear sequential piddle to loop over
  my $dtheta  = $nc->getatt( 'seasonde_Angular_Resolution', sprintf('seasonde_Header_%s',uc($self->{codenames}->{sos})) )->sclr;
  my $bears   = $nc->get( 'ssr_Surface_Radial_Direction_Of_Sea_Water_Velocity' );
  my $bearinc = floor(($bears->min - floor($bears->min)) + ($bears->min % $dtheta))->sclr;
  my $thetas  = zeroes(360/$dtheta)->xlinvals(0,(360-$dtheta)) + $bearinc;

  # defined a temporary file to output radial grid and erase whatever previous one may have existed
  my $rad_grid_file  = sprintf('%s/%s',$self->{local_server}->{directories}->{tmp},$self->{grid}->{files}->{tmp_ss_rad});
  unlink( $rad_grid_file ) if (-e $rad_grid_file);

  # loop over each bearing (angle) and compute lon/lat at each range step using GMT project function
  for (my $l1=0;$l1<($thetas->nelem);$l1++) {

    my $sysstr = sprintf('%s/project -C%f/%f -A%i -G%f -L%f/%f -Q >> %s',
			 $self->{gmt}->{bin_directory},
			 $lon0,
			 $lat0,
			 $thetas($l1)->sclr,
			 ($drng/1e3),
			 ($drng/1e3),
			 ($rng_m/1e3),
			 $rad_grid_file
			);

    system( $sysstr );

  }

  # read in the computed lon/lat grid into HASH
  ($self->{grid}->{longitudes},$self->{grid}->{latitudes}) = rcols $rad_grid_file, 0,1;

  printf("SeaSonde radial grid file %s created and loaded into hash\n",$rad_grid_file) if ($self->{misc}->{verbose}>=3);

  return $self;

}
################################################################################
sub read_grid {

  my $self = shift;

  if ( $self->HFR::ACORN::is_wera ) {

    $self->HFR::ACORN::Gridding::read_wera_grid;

  } elsif ( $self->HFR::ACORN::is_site_seasonde ) {

    $self->HFR::ACORN::Gridding::read_seasonde_site_grid;

  } else {

    # This uses the last file in the constructed list of files, there are a couple of problems with this approach
    # 1.) if the last file does not exist then this will completely choke the script
    # 2.) if the grid has changed from start_time to stop_time then this change will not be accounted for
    $self->HFR::ACORN::Gridding::construct_seasonde_radial_grid( $self->{ncf}->{list_of_files}->atstr(-1) );

  }

  return $self;

}


=head1 AUTHOR

Atwater, Daniel Patrick Lewis, C<< <danielpath2o at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hfr-acorn-gridding at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HFR-ACORN-Gridding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HFR::ACORN::Gridding


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HFR-ACORN-Gridding>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HFR-ACORN-Gridding>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HFR-ACORN-Gridding>

=item * Search CPAN

L<http://search.cpan.org/dist/HFR-ACORN-Gridding/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Atwater, Daniel Patrick Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HFR::ACORN::Gridding
