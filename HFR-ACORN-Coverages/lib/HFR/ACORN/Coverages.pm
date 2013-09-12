package HFR::ACORN::Coverages;

use strict;
use HFR;
use HFR::ACORN;
use PDL;
use PDL::NiceSlice;
use PDL::NetCDF;
use PDL::Char;
use Date::Calc qw( Localtime );
use LWP::Simple;

our $VERSION = '0.01';

################################################################################
sub construct_figure_file {

  my $self = shift;

  if ( $self->HFR::ACORN::is_site  and (!defined $self->{local_server}->{directories}->{figures}->{current}) ) {

    $self->{local_server}->{directories}->{figures}->{current} = sprintf('%s/%s/coverages',$self->{local_server}->{directories}->{figures}->{base},$self->{codenames}->{sos});

  } else {

    $self->{local_server}->{directories}->{figures}->{current} = sprintf('%s/%s/%s/coverages',$self->{local_server}->{directories}->{figures}->{base},$self->{codenames}->{site},$self->{codenames}->{sos});

  }

  if (!(-d $self->{local_server}->{directories}->{figures}->{current})) { 

    umask 000; # ensure the permissions you set are the ones you get
    mkdir $self->{local_server}->{directories}->{figures}->{current};
    chmod 0755, $self->{local_server}->{directories}->{figures}->{current};

  }

  my $t0 = $self->{time}->{start}->sclr;
  my $tN = $self->{time}->{stop}->sclr;

  my ($yr0,$mo0,$dy0, $hr0,$mn0,$sc0, $doy0,$dow0,$dst0) = Localtime($t0);
  my ($yrN,$moN,$dyN, $hrN,$mnN,$scN, $doyN,$dowN,$dstN) = Localtime($tN);

  $self->{coverages}->{files}->{figure} = sprintf('%s/%s_coverage_FROM_%04d%02d%02dT%02d%02d_TO_%04d%02d%02dT%02d%02d.%s',
                                                  $self->{local_server}->{directories}->{figures}->{current},
                                                  $self->{codenames}->{sos},
                                                  $yr0,$mo0,$dy0,$hr0,$mn0,
                                                  $yrN,$moN,$dyN,$hrN,$mnN,
                                                  $self->{gmt}->{files}->{suffix}
                                                 );

  return $self;

}
################################################################################
sub compute_coverage {

    my $self = shift;

    # INTIALISE THE COVERAGE DATA
    # Think of it as occurrences
    my $occs = zeros($self->{grid}->{longitudes}->nelem,1);

    # loop over each file
    # extract lon/lat from each file
    # using attributes and GMT function 'grdmask' find all the lon/lat pairs within 10 meters of each grid point
    # keep track of these occurrences -- i.e. keep a running total
    my @filedims = $self->{ncf}->{list_of_files}->dims;
    for (my $l1=0;$l1<$filedims[1];$l1++) {

        # SKIP MISSING FILES
        # Caveat: if it is the last file in the loop then write out the data because there could be enough
        my $urlhead = LWP::Simple::head($self->{ncf}->{list_of_files_url}->atstr($l1));
        unless (UNIVERSAL::isa( $urlhead, "HASH" )) {

            printf("\nFILE NOTE FOUND: %s\n\n", $self->{ncf}->{list_of_files}->atstr($l1)) if ($self->{misc}->{verbose}>0);
            if ( ($l1==$filedims[1]-1) ) { $self->HFR::ACORN::Coverages::write_coverages( $occs ); return $self; }
            next;

        }

        # LOAD THE NETCDF FILE
        printf("Extracting lon/lat from: %s\n", $self->{ncf}->{list_of_files}->atstr($l1)) if ($self->{misc}->{verbose}>0);
        my $ncfile = $self->{ncf}->{list_of_files}->atstr($l1);
        my $nc = PDL::NetCDF->new( $ncfile );

        # SEASOND VECTORS CONDITION
        if ($self->HFR::ACORN::is_site_seasonde) {

            # For the site data will go off any non-zero currents ('speed'>0)
            my $speed = $nc->get('ssr_Surface_Eastward_Sea_Water_Velocity');
            # since speed is 'gridded' we need to reshape it into the same dimensions as the grid
            $speed->reshape($self->{grid}->{longitudes}->nelem);
            $occs( which( ($speed < $self->{flags}->{site_badval}) & ($speed > 0) ))++;

            printf("SeaSonde vector cumulative occurrences: %d\n", sum($occs) ) if ($self->{misc}->{verbose}>1);

            # WERA VECTOR CONDITION
        } elsif ($self->HFR::ACORN::is_site_wera) {

            # get the grid on the same indeces since there are no indeces in the nc file
            if ($l1==0) {

                my $latD = $nc->get('LATITUDE');
                my $lonD = $nc->get('LONGITUDE');
                my $grid = cat( $lonD->(:, *$latD->nelem), $latD->(*$lonD->nelem, :) )->mv(-1,0);
                my $LAT  = $grid(1,:,:);
                my $LON  = $grid(0,:,:);
                $LON->reshape( ($lonD->nelem)*($latD->nelem) );
                $LAT->reshape( ($lonD->nelem)*($latD->nelem) );
                $self->{grid}->{latitudes}  = $LAT;
                $self->{grid}->{longitudes} = $LON;
                $occs = zeros($self->{grid}->{longitudes}->nelem,1);

            }

            # For the site data will go off any non-zero currents ('speed'>0)
            my $speed = $nc->get('SPEED');

            # since speed is 'gridded' we need to reshape it into the same dimensions as the grid
            $speed->reshape($self->{grid}->{longitudes}->nelem);
            $occs( which( ($speed < $self->{flags}->{site_badval}) & ($speed > 0) ) )++;

            printf("WERA Vector cumulative occurrences: %d\n", sum($occs) ) if ($self->{misc}->{verbose}>1);

            # RADIAL FILES
        } else {

            my $latD = $nc->get('LATITUDE');
            my $lonD = $nc->get('LONGITUDE');
            my $N    = $latD->nelem;

            # LOOPING OVER EACH RADIAL GRID POINT
            printf("Station coverage on %i data lon/lats on %s \n",$N,$self->{grid}->{files}->{primary}) if ($self->{misc}->{verbose}>1) ;
            for (my $l2=0;$l2<$N;$l2++) {

                # compute distances, Law of Cosines is sufficient
                my $D = HFR::distance_law_of_cosines( $lonD($l2) , $latD($l2) , $self->{grid}->{longitudes} , $self->{grid}->{latitudes} );

                # Log grid indeces that are within n kilometers of lon/lat data 
                if ( any( ($D < $self->{tolerances}->{data_to_grid_distance}) & ($D > 0) ) ) {

                    $occs( which( ($D < $self->{tolerances}->{data_to_grid_distance}) & ($D > 0) ) )++;
                    printf("Radial cumulative occurrences: %d\n", sum($occs) ) if ($self->{misc}->{verbose}>2);

                }
            }
        }

        # ON THE LAST INTERATION OF THE LOOP WRITE OUT THE DATA
        if ( ($l1==$filedims[1]-1) ) { $self->HFR::ACORN::Coverages::write_coverages( $occs ); return $self; }

    }
}
################################################################################
sub write_coverages {

    my $self = shift;

    my $occs = shift;

    my $percs = $occs/($occs->max);
    my $ind0  = which($percs>0);
    my $lonG  = $self->{grid}->{longitudes};
    my $latG  = $self->{grid}->{latitudes};
    print "$lonG\n\n";
    my $data_out = $percs($ind0);
    my $lonG_out = $lonG($ind0);
    print "$lonG_out\n";
    my $latG_out = $latG($ind0);
    #$percs(which($percs==0)).=nan;
    $self->{coverages}->{data}  = $data_out;
    $self->{grid}->{longitudes} = $lonG_out;
    $self->{grid}->{latitudes}  = $latG_out;

    # write out data
    $self->{coverages}->{files}->{full_path} = $self->{local_server}->{directories}->{tmp}.'/'.$self->{coverages}->{files}->{data_filename};
    unlink($self->{coverages}->{files}->{full_path}) if (-e $self->{coverages}->{files}->{full_path});
    wcols $self->{grid}->{longitudes},$self->{grid}->{latitudes},$self->{coverages}->{data}, $self->{coverages}->{files}->{full_path};

    printf("\nCreated temporary coverage data file: %s\n",$self->{coverages}->{files}->{full_path}) if (-e $self->{coverages}->{files}->{full_path} and $self->{misc}->{verbose}>0);

    return $self;

}

__END__

=head1 NAME

Coverages.pm

=head1 SYNOPSIS

Object-orientated Perl package for computing coverages (distributions) over time for HF radar radial or vector measurements.

Part of HFR package. See documentation on L<HFR> and L<HFR::ACORN>.

=head2 METHODS

=head3 construct_figure_file

=head3 compute_coverage

=head3 write_coverages

=head1 PERL PACKAGES

=over 4

=item L<HFR>

=item L<HFR::ACORN>

=item L<PDL>

=item L<PDL::NiceSlice>

=item L<PDL::NetCDF>

=item L<PDL::Char>

=item L<Date::Calc>

=item L<LWP::Simple>

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

1; # End of HFR::ACORN::Coverages
