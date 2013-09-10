package HFR::ACORN::FileOps;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use PDL;
use PDL::NiceSlice;
use PDL::Char;
use Date::Calc qw( Localtime );
use HFR::ACORN;

our $VERSION = '0.01';

=head1 NAME

HFR::ACORN::FileOps - The great new HFR::ACORN::FileOps!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 define_full_path

=cut

################################################################################
sub define_full_path {

  my $self = shift;

  # DIRECTORY DATA TYPE
  my $directory_data_type;
  if ( $self->HFR::ACORN::is_site ) { #vectors (site)

      if ( $self->HFR::ACORN::is_wera ) { #wera

          if ( $self->{misc}->{use_qc} ) { #qc

          $directory_data_type = $self->{imos_data_portal}->{wera_vector_directory_qc};

          } else { #non-qc

              $directory_data_type = $self->{imos_data_portal}->{wera_vector_directory_nonqc};

          }

      } else { #seasonde

          if ( $self->{misc}->{use_qc} ) { #qc

              $directory_data_type = $self->{imos_data_portal}->{seasonde_vector_directory};

          } else { #non-qc

              $directory_data_type = $self->{imos_data_portal}->{seasonde_vector_directory};

          }

      }

  } else { #radials (station)

      if ( $self->{misc}->{use_qc}) { #qc

          $directory_data_type = $self->{imos_data_portal}->{station_directory_qc};

      } else { #non-qc

          $directory_data_type = $self->{imos_data_portal}->{station_directory_nonqc};

      }

  }

  # DETERMINE WHICH SERVER
  if ( $self->{misc}->{use_imos} ) {

      $self->{ncf}->{base_directory} = $self->{imos_data_portal}->{url_base};

  } else {

      $self->{ncf}->{base_directory} = $self->{acorn_server}->{url_base};

  }

  # ASSIGN OUT
  $self->{ncf}->{path} = sprintf( "%s/%s/%s/%04d/%02d/%02d" ,
                                  $self->{ncf}->{base_directory} ,
                                  $directory_data_type,
                                  uc($self->{codenames}->{sos}) ,
                                  $self->{ncf}->{year} ,
                                  $self->{ncf}->{month} ,
                                  $self->{ncf}->{day} );

  return $self;

}
################################################################################
sub define_file_time {

  my $self                                 = shift;
  my $t                                    = shift;
  my ($yr,$mo,$dy,$HR,$MN,$SC,$DD,$DW,$DT) = Localtime($t);
  $self->{ncf}->{time}                     = sprintf "%04d%02d%02dT%02d%02d00Z", $yr,$mo,$dy,$HR,$MN;
  $self->{ncf}->{year}                     = $yr;
  $self->{ncf}->{month}                    = $mo;
  $self->{ncf}->{day}                      = $dy;
  return $self;

}
################################################################################
sub define_filename {

  my $self = shift;

  my ($data_version,$data_type,$qc_version);

  # DATA VERSION
  if ($self->HFR::ACORN::is_site) {

    $data_version = $self->{ncf}->{vector_data_version};

    # VECTOR DATA TYPES
    if ($self->HFR::ACORN::is_codar) {

        $data_type = $self->{ncf}->{cos_vector_data_type};

    } else {

        $data_type = $self->{ncf}->{wera_vector_data_type};

    }

  } else {

    $data_version = $self->{ncf}->{radial_data_version};
    $data_type    = $self->{ncf}->{radial_data_type};

  }

  if ($self->{misc}->{use_qc}) {

    $qc_version = $self->{ncf}->{version_qc};

  } else {

    $qc_version = $self->{ncf}->{version_nonqc};

  }

  $self->{ncf}->{filename} = sprintf("%s_%s_%s_%s_%s_%s.%s" ,
                                     uc($self->{ncf}->{prefix}),
                                     uc($data_version),
                                     $self->{ncf}->{time},
                                     uc($self->{codenames}->{sos}),
                                     uc($qc_version),
                                     $data_type,
                                     $self->{ncf}->{suffix},
                                    );

  $self->{ncf}->{url_filename} = sprintf("%s_%s_%s_%s_%s_%s.%s.%s" ,
                                         uc($self->{ncf}->{prefix}),
                                         uc($data_version),
                                         $self->{ncf}->{time},
                                         uc($self->{codenames}->{sos}),
                                         uc($qc_version),
                                         $data_type,
                                         $self->{ncf}->{suffix},
                                         $self->{ncf}->{suffix_url},
                                        );

  return $self;

}
################################################################################
sub construct_file_list {

  my $self = shift;

  # make sure the parameters are in the correct format
  $self->HFR::ACORN::determine_codename;
  $self->HFR::ACORN::determine_datetime;
  $self->HFR::ACORN::determine_site;

  # determine how often netcdf files are created
  $self->HFR::ACORN::determine_delta_time;
  $self->HFR::ACORN::determine_offset_time;

  # determine how many intervals to loop over
  my $t_n = rint(( $self->{time}->{stop} - $self->{time}->{start} ) / $self->{time}->{dt})->sclr;

  my @full_file_list     = ();
  my @full_file_list_url = ();

  # create a list of files or just a single file
  if ( $t_n > 2 ) {

    my $tmp1 = ( zeroes(($t_n - 1),1)->xlinvals(1,($t_n - 1)) * $self->{time}->{dt} ) + $self->{time}->{start};
    my $tmp2 = pdl[ $self->{time}->{start} ];
    my $t    = $tmp2->append($tmp1);

    foreach ($t->list) {

      $self->HFR::ACORN::FileOps::define_file_time($_);
      $self->HFR::ACORN::FileOps::define_filename;
      $self->HFR::ACORN::FileOps::define_full_path;

      push @full_file_list , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{filename} );
      push @full_file_list_url , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{url_filename} );

    }

  } elsif ( $t_n == 2 ) {

    my $t = pdl[$self->{time}->{start},$self->{time}->{start}+$self->{time}->{dt},$self->{time}->{stop}];

    foreach ($t->list) {

      $self->HFR::ACORN::FileOps::define_file_time($_);
      $self->HFR::ACORN::FileOps::define_filename;
      $self->HFR::ACORN::FileOps::define_full_path;

      push @full_file_list , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{filename} );
      push @full_file_list_url , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{url_filename} );

    }

  } elsif ( $t_n == 1 ) {

    my $t = pdl[$self->{time}->{start},$self->{time}->{stop}];

    foreach ($t->list) {

      $self->HFR::ACORN::FileOps::define_file_time($_);
      $self->HFR::ACORN::FileOps::define_filename;
      $self->HFR::ACORN::FileOps::define_full_path;

      push @full_file_list , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{filename} );
      push @full_file_list_url , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{url_filename} );

    }

  } else {

    my $t = $self->{time}->{start};

    $self->HFR::ACORN::FileOps::define_file_time($_);
    $self->HFR::ACORN::FileOps::define_filename;
    $self->HFR::ACORN::FileOps::define_full_path;

    push @full_file_list , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{filename} ) ;
    push @full_file_list_url , sprintf( "%s/%s" , $self->{ncf}->{path},$self->{ncf}->{url_filename} ) ;

  }

  $self->{ncf}->{list_of_files}     = PDL::Char->new( @full_file_list );
  $self->{ncf}->{list_of_files_url} = PDL::Char->new( @full_file_list_url );

  return $self;

}


=head1 AUTHOR

Atwater, Daniel Patrick Lewis, C<< <danielpath2o at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hfr-acorn-fileops at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HFR-ACORN-FileOps>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HFR::ACORN::FileOps


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HFR-ACORN-FileOps>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HFR-ACORN-FileOps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HFR-ACORN-FileOps>

=item * Search CPAN

L<http://search.cpan.org/dist/HFR-ACORN-FileOps/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Atwater, Daniel Patrick Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HFR::ACORN::FileOps
