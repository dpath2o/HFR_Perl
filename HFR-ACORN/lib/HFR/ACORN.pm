package HFR::ACORN;

use 5.006;
use strict;
use warnings;
use Date::Parse;
use Date::Calc qw ( Localtime );
use PDL;
use YAML::XS qw(LoadFile);

our $VERSION = '0.1';

################################################################################
sub new {

   my($class, %args) = @_;
   my $self          = bless( {} , $class );

   # load configuration file and bless to self
   my $config_file = exists $args{config_file} ? $args{config_file} : $ENV{"HOME"}.'/acorn_perl.yml';
   $self = LoadFile $config_file;

   # REQUIRED INPUT PARAMETERS
   my $sos                   = exists $args{sos} ? $args{sos} : $self->{codenames}->{sos}; 
   $self->{codenames}->{sos} = $sos;
   my $start                 = exists $args{start} ? $args{start} : $self->{time}->{start};
   $self->{time}->{start}    = $start;
   my $stop                  = exists $args{stop} ? $args{stop} : $self->{time}->{stop};
   $self->{time}->{stop}     = $stop;
   my $verbose               = exists $args{verbose} ? $args{verbose} : $self->{misc}->{verbose};
   $self->{misc}->{verbose}  = $verbose;

   # RETURN
   bless $self;
   return $self;

}
################################################################################
sub is_wera {

  my $self = shift;

  if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_all}} ) { 
      return 1;
  } else { 
      return 0;
  }

}
################################################################################
sub is_wera_station {

    my $self = shift;

    if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_stations}} ) {
        return 1;
    } else {
        return 0;
    }

}
################################################################################
sub is_codar {

    my $self = shift;

    if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{codar_all}} ) {
        return 1;
    } else {
        return 0;
    }

}
################################################################################
sub is_codar_station {

    my $self = shift;

    if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{codar_stations}} ) {
        return 1;
    } else {
        return 0;
    }

}
################################################################################
sub is_site {

  my $self = shift;

  if ($self->{codenames}->{sos} ~~ @{$self->{codenames}->{sites}} ) {
      return 1;
  } else {
      return 0;
  }

}
################################################################################
sub is_site_seasonde {

  my $self = shift;

  if ($self->{codenames}->{sos} ~~ @{$self->{codenames}->{codar_sites}} ) {
      return 1;
  } else {
      return 0;
  }

}
################################################################################
sub is_site_wera {

  my $self = shift;

  if ($self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_sites}} ) {
      return 1;
  } else {
      return 0;
  }

}
################################################################################
sub determine_site {

  my $self = shift;

  my $regex1 = qr/$self->{codenames}->{green_head}|$self->{codenames}->{lancelin}|$self->{codenames}->{cervantes}|$self->{codenames}->{seabird}|$self->{codenames}->{turquoise_coast}/i;
  my $regex2 = qr/$self->{codenames}->{nora_creina}|$self->{codenames}->{blackfellows_caves}|$self->{codenames}->{bonney_coast}/i;
  my $regex3 = qr/$self->{codenames}->{fremantle}|$self->{codenames}->{guilderton}|$self->{codenames}->{rottnest_island}/i;
  my $regex4 = qr/$self->{codenames}->{cape_wiles}|$self->{codenames}->{cape_spencer}|$self->{codenames}->{south_australia_gulf}/i;
  my $regex5 = qr/$self->{codenames}->{north_nambucca}|$self->{codenames}->{red_rock}|$self->{codenames}->{coffs_harbour}/i;
  my $regex6 = qr/$self->{codenames}->{lady_elliot_island}|$self->{codenames}->{tannum_sands}|$self->{codenames}->{capricorn_bunker_group}/i;

  if ($self->{codenames}->{sos} =~ $regex1) { $self->{codenames}->{site} = $self->{codenames}->{turquoise_coast}; }
  elsif ($self->{codenames}->{sos} =~ $regex2) { $self->{codenames}->{site} = $self->{codenames}->{bonney_coast}; }
  elsif ($self->{codenames}->{sos} =~ $regex3) { $self->{codenames}->{site} = $self->{codenames}->{rottnest_island}; }
  elsif ($self->{codenames}->{sos} =~ $regex4) { $self->{codenames}->{site} = $self->{codenames}->{south_australia_gulf}; }
  elsif ($self->{codenames}->{sos} =~ $regex5) { $self->{codenames}->{site} = $self->{codenames}->{coffs_harbour}; }
  elsif ($self->{codenames}->{sos} =~ $regex6) { $self->{codenames}->{site} = $self->{codenames}->{capricorn_bunker_group}; }
  else { warn 'given station name is NOT and ACORN site'; $self->{codenames}->{site} = ''; }

  return $self;

}
################################################################################
sub determine_datetime {

  my $self = shift;

  my $t0 = $self->{time}->{start};
  my $tN = $self->{time}->{stop};

  $self->{time}->{start} = pdl[ str2time( $t0 ) ];
  $self->{time}->{stop}  = pdl[ str2time( $tN ) ];

  return $self;

}
################################################################################
sub define_datestrs {

  my $self = shift;

  my $t0 = $self->{time}->{start}->sclr;
  my $tN = $self->{time}->{stop}->sclr;

  my ($yr0,$mo0,$dy0, $hr0,$mn0,$sc0, $doy0,$dow0,$dst0) = Localtime($t0);
  my ($yrN,$moN,$dyN, $hrN,$mnN,$scN, $doyN,$dowN,$dstN) = Localtime($tN);

  my $t0_str = sprintf('%04d-%02d-%02d %02d:%02d',$yr0,$mo0,$dy0,$hr0,$mn0);
  my $tN_str = sprintf('%04d-%02d-%02d %02d:%02d',$yrN,$moN,$dyN,$hrN,$mnN);

  $self->{time}->{start_str} = $t0_str;
  $self->{time}->{stop_str}  = $tN_str;

  return $self;

}
################################################################################
sub determine_delta_time {

  my $self = shift;

  if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_stations}} ) {

    $self->{time}->{dt} = pdl[600]; #10 minutes
    printf("Delta time of 600 seconds for site/station %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  } elsif ( $self->{codenames}->{sos} ~~ [ @{$self->{codenames}->{codar_all}} , @{$self->{codenames}->{wera_sites}}] ) {

    $self->{time}->{dt} = pdl[3600]; #60 minutes
    printf("Delta time of 3600 seconds for site/station %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  } else {

    die "could not determine delta time";

  }

  return $self;

}
################################################################################
sub determine_offset_time {

  my $self = shift;

  if ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_t_off_5}} ) { 

    $self->{time}->{start}+=pdl[300];
    $self->{time}->{stop}+=pdl[300];
    printf("Time offset by 300 seconds for station %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  } elsif ( $self->{codenames}->{sos} ~~ @{$self->{codenames}->{wera_sites}} ) {

    $self->{time}->{start}+=pdl[1800];
    $self->{time}->{stop}+=pdl[1800];
    printf("Time offset by 1800 seconds for site %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  } else {

    printf("Time offset not necessary for %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  }

  return $self;

}
################################################################################
sub determine_codename {

  my $self = shift;

  if ( $self->{codenames}->{sos} =~ /cervantes|crvt/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{cervantes};

  } elsif ( $self->{codenames}->{sos} =~ /green head|ghed/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{green_head};

  } elsif ( $self->{codenames}->{sos} =~ /lancelin|lanc/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{lancelin};

  } elsif ( $self->{codenames}->{sos} =~ /seabird|sbrd/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{seabird};

  } elsif ( $self->{codenames}->{sos} =~ /guilderton|gui/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{guilderton};

  } elsif ( $self->{codenames}->{sos} =~ /fremantle|fre/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{fremantle};

  } elsif ( $self->{codenames}->{sos} =~ /cape wiles|eyre peninsula|cwi/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{cape_wiles};

  } elsif ( $self->{codenames}->{sos} =~ /cape spencer|yorke peninsula|csp/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{cape_spencer};

  } elsif ( $self->{codenames}->{sos} =~ /nora|nora creina|robe|nocr/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{nora_creina};

  } elsif ( $self->{codenames}->{sos} =~ /blackfellows|blackfellows caves|bfcv/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{blackfellows_caves};

  } elsif ( $self->{codenames}->{sos} =~ /nambucca|nambucca heads|nnb/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{north_nambucca};

  } elsif ( $self->{codenames}->{sos} =~ /red rock|rrk/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{red_rock};

  } elsif ( $self->{codenames}->{sos} =~ /lady elliot|lady elliot island|lei/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{lady_elliot_island};

  } elsif ( $self->{codenames}->{sos} =~ /tannum|tannum sands|tan/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{tannum_sands};

  } elsif ( $self->{codenames}->{sos} =~ /turquoise|turquoise coast|turq/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{turquoise_coast};

  } elsif ( $self->{codenames}->{sos} =~ /rottnest|rottnest island|rot/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{rottnest_island};

  } elsif ( $self->{codenames}->{sos} =~ /sa gulf|south australian? gulf|sag/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{south_australia_gulf};

  } elsif ( $self->{codenames}->{sos} =~ /bonney coast|limestone coast|bonc/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{bonney_coast};

  } elsif ( $self->{codenames}->{sos} =~ /coffs|coffs harbour|cof/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{coffs_harbour};

  } elsif ( $self->{codenames}->{sos} =~ /capricorn|capricorn bunker group|cbg/i ) {

    $self->{codenames}->{sos} = $self->{codenames}->{capricorn_bunker_group};

  }

  printf("Station/site is %s\n",$self->{codenames}->{sos}) if ($self->{misc}->{verbose}>=3);

  return $self;

}

__END__

=head1 NAME

HFR::ACORN - for use with HF Radar (HFR) Australian Coastal Ocean Radar Network (ACORN) data.

=head1 SYNOPSIS

In a broad sense, HFR::ACORN is intended to be used as a class which utilises methods for manipulating ACORN derived data.  Plainly speaking, what the author intends is that this module be used in an object-orientated way for extracting, visualising and running various computations on ACORN derived data.

Here's a quick example of one of the intended uses. Say you'd like to build a list of radial files from ACORN Guilderton (GUI) station for certain time period:

=head2 EXAMPLE

   use HFR::ACORN;
   use HFR::ACORN::FileOps;
   use PDL::Lite;
   use PDL::Char;
   my $acorn = HFR::ACORN->new( sos => 'guilderton' , start => '12 sep 2011' , stop => '12 sep 2012 01:30' );
   $acorn->HFR::ACORN::FileOps::construct_file_list;
   if (-e $acorn->{full_file_list}->atstr(0)) {
      print "$_ exists\n";
   } else {
      print "$_ does NOT exists\n";
   }

The above example checks to see if the first file, in the list of files created, exists, and then prints a message on its existence.

Plenty of assumptions (default parameters) are made in the above example when calling C<< HFR::ACORN->new >>; B<the backbone of HFR::ACORN is the B<YAML configuration file>. See L<HFR::YAML>.>

=head1 REQUIREMENTS

The following is a list of required packages/modules:

=over 6

=item L<Date::Parse>

=item L<Date::Calc>

=item L<PDL::Lite>

=item L<YAML::XS>

=back

=head1 METHODS

=head2 new

Returns a new ACORN object, which has loaded the file configuration file (see L<HFR::YAML>)

=head2 is_wera

Given C<< $acorn->{sos} >> check to see if that name is a I<WERA station or site>

=head2 is_site

Given C<< $acorn->{sos} >> check to see if that name is a I<site>

=head2 is_site_seasonde

Given C<< $acorn->{sos} >> check to see if that name is a I<SeaSonde site>

=head2 is_site_wera

Given C<< $acorn->{sos} >> check to see if that name is a I<WERA site>

=head2 determine_site

Given C<< $acorn->{sos} >> return C<< $acorn->{site} >>. This may appear a little confusing at first, but the intention here is to determine if the U<Station or Site> parameter from the configuration file or given as an input when initialising this class B<I<is>> a site! The code in this method uses text that is specific to ACORN sites and therefore is the begining of the distinction as to why this class is intended just for ACORN derived data.

=head2 determine_datetime

Use C<< Date::Parse::str2time >> on date/time strings defined in C<< $acorn->{time}->{start} >> and C<< $acorn->{time}->{stop} >>, which should be parse-able date-strings, and return these same elements as POSIX timestamps as a PDL scalar. See L<Date::Parse> and L<PDL::Lite>.

=head2 define_datestr

Use C<Date::Calc::Localtime> on C<< $acorn->{time}->{start} >> and C<< $acorn->{time}->{stop} >>, which should be PDL scalar POSIX timestamps, and return  C<< $acorn->{time}->{start_str} >> and  C<< $acorn->{time}->{stop_str} >> as date/time scalar strings.

=head2 determine_delta_time

ACORN stations output data files at different rates. B<At present> this method uses C<$acorn->{sos}> to determine the output time of either the radial or vector files. I<This method really needs to be made more robust. Possibly renaming it to be more specific about what it does is the most sensible thing to do as a first step, but really it needs to clue on an YAML parameter(s).>

=head2 determine_offset_time

ACORN WERA stations use FMCW and therefore are not on at the same time (not that FMCW makes this exclusive). Regardless, ACORN WERA stations collect every 10 minutes for roughly 5 minute sampling time lengths (1024 sweeps at 0.26 seconds). Since this is a configuration setting of a particular station then use the YAML file to look up which stations are either on the 00 minute or 05 minute sampling interval.

=head2 determine_codename

Given C<< $acorn->{sos} >> as either an input or defined YAML parameter return the ACORN codename to the same object element.

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
