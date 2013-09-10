package HFR::ACORN::NetCDF;

use 5.012003;
use strict;
use warnings;

use HFR;
use HFR::Constants qw(:all);

use PDL::Lite;
use PDL::NetCDF;
use PDL::NiceSlice;
use PDL::Char;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HFR::ACORN::NetCDF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';


# Preloaded methods go here.
################################################################################
sub vector_data_extract {

  my ($vars,$nc,$STA) = @_;
  my @VARS       = @$vars;
  my($S,$D,$U,$V,$LN,$LT,$ln,$lt);

  # loop over each variable to extract
  foreach my $l2 (@VARS) {

    if ($l2 eq 'ssr_Surface_Eastward_Sea_Water_Velocity' or $l2 eq 'UCUR') {
      $U = $nc->get($l2);
      $U = $U->reshape;
      $U->badvalue(9999);
      $U->badflag(1);
      $U->inplace->setbadtonan;
    } elsif ($l2 eq 'ssr_Surface_Northward_Sea_Water_Velocity' or $l2 eq 'VCUR') {
      $V = $nc->get($l2);
      $V = $V-reshape();
      $V->badvalue(9999);
      $V->badflag(1);
      $V->inplace->setbadtonan;
    } elsif ($l2 eq 'LONGITUDE') {
      $ln = $nc->get($l2);
    } elsif ($l2 eq 'LATITUDE') {
      $lt = $nc->get($l2);
    }
  }

  # convert u and v to speed and direction
  $S = sqrt( $U**2 + $V**2 );
  $D = ((180/PI)*(atan2($V,$U))) % 360;

  # get lon lat into same dims as speed and direction
  if ( grep($_ eq $STA,("sag","rot","cbg","cof")) ) { #NEED TO CHANGE THIS IN THE FUTURE
    $LN  = $ln->(:,*$lt->nelem);
    $LT  = $lt->(*$ln->nelem,:);
  }

  return($LN,$LT,$D,$S);

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HFR::ACORN::NetCDF - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HFR::ACORN::NetCDF;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HFR::ACORN::NetCDF, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Daniel Patrick Lewis Atwater, E<lt>dpath2o@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Daniel Patrick Lewis Atwater

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
