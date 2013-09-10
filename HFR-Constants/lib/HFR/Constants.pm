package HFR::Constants;

use 5.006;
use strict;
use warnings;
use base 'Exporter';

=head1 NAME

HFR::Constants - The great new HFR::Constants!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use HFR::Constants;

=head1 EXPORT

=cut

use constant earth_radius => 6371.009;
use constant PI           => 3.14159265358979323846;

our @EXPORT_OK = qw( earth_radius );

#Readonly::array  our @seasonde_suffixes => qw( ts rs cs cs4 tuv ruv euv sdt wls wl4 wv4 hdt rdt xdt sdt trk txt );


=head1 AUTHOR

Atwater, Daniel Patrick Lewis, C<< <danielpath2o at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hfr-constants at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HFR-Constants>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HFR::Constants


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HFR-Constants>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HFR-Constants>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HFR-Constants>

=item * Search CPAN

L<http://search.cpan.org/dist/HFR-Constants/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Atwater, Daniel Patrick Lewis.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HFR::Constants
