#!/usr/bin/perl
#
# seasonde_station_data_transfer_push.pl
#
# This perl script is intended to be called for pushing SeaSonde files from the station computer
# to a remote server.
#
# This file uses HFR::FileTransfer module and it's associated modules. I encourage you to read the
# documentation on this module to understand what that module is doing or before modifying this script
# to suit your needs.

################################################################################
# LOAD MODULES/LIBRARIES
use strict;
use DateTime;
use Getopt::Long;
use Pod::Usage;
use Log::LogLite;
use Net::NSCA::Client;
use HFR::FileTransfer;

################################################################################
# LOAD CURRENT SYSTEM TIME
my $dt = DateTime->now;

################################################################################
# INITIALISE INPUTS
my ($sf,$rh,$dd,$station);
my $ad        = '/codar/seasonde/archives';
my $sd        = '/codar/seasonde/data/radials/measpattern';
my $qd        = "$ENV{HOME}/queued";
my $ssh_key   = "$ENV{HOME}/.ssh/id_rsa";
my $log_file  = sprintf('/codar/seasonde/logs/filetransfer.log');
my $logit     = 0;
my $log_level = 6;
my $queued    = 0;
my $unqueue   = 0;
my $user      = 'codar';
my $verbose   = 0;
my $debug     = 0;
my $help_msg  = 0;

################################################################################
# GET INPUTS
my $result = GetOptions (
			 "sf|source_file=s"           => \$sf,
			 "sd|source_directory=s"      => \$sd,
			 "qd|queued_directory=s"      => \$qd,
			 "ad|archive_directory=s"     => \$ad,
			 "rh|remote_host=s"           => \$rh,
			 "dd|destination_directory=s" => \$dd,
			 "ssh_key_file=s"             => \$ssh_key,
			 "logit"                      => \$logit,
			 "log_file=s"                 => \$log_file,
			 "station=s"                  => \$station,
			 "queued"                     => \$queued,
			 "unqueue"                    => \$unqueue,
			 "user"                       => \$user,
			 "v|verbose"                  => \$verbose,
			 "d|debug"                    => \$debug,
                         "h|help!"                    => \$help_msg) or usage("Invalid commmand line options.");

################################################################################
# PRINT USAGE AND EXIT
usage("HELP MESSAGE:") if ( $help_msg==1 );

################################################################################
# OPEN LOG
my $log = new Log::LogLite( $log_file , $log_level );

################################################################################
# PRIMARY CONDITION: queued or not single file transfer
if ( $queued==1 ) {

  # exit here if any of the directories do  not exist
  if ( !(-d $sd) ) {

    my $msg = "Source directory :: $sd\nEither undefined as an input argument OR the directory itself does not exist ... \nERROR! EXITING PROGRAM $0\n";
    $log->write( $msg , $log_level ) if ($logit);
    exit;

  }

  if ( !(-d $qd) ) {

    my $msg = "Queued directory :: $qd\nEither undefined as an input argument OR the directory itself does not exist ... \nERROR! EXITING PROGRAM $0\n";
    $log->write( $msg , $log_level ) if ($logit);
    exit;

  }

  if ( !(-d $ad) ) {

    my $msg = "Archive directory :: $ad\nEither undefined as an input argument OR the directory itself does not exist ... \nERROR! EXITING PROGRAM $0\n";
    $log->write( $msg , $log_level ) if ($logit);
    exit;

  }

  my $xfer = HFR::FileTransfer->new_transfer(
					     source_directory      => $sd,
					     queued_directory      => $qd,
					     archive_directory     => $ad,
                                             remote_host           => $rh,
                                             destination_directory => $dd,
					     ssh_key_file          => $ssh_key,
					     log_file              => $log_file,
					     logit                 => $logit,
					     logger                => $log,
					     user                  => $user,
					     unqueue_it            => $unqueue,
					     verbose               => $verbose,
					     debug                 => $debug );
  $xfer->HFR::FileTransfer::queued_push;

} else {

  # exit if file does not exist in source path, if this is true in real-time usage then there
  # is something drastically wrong with SeaSonde software as this is called from a hook within
  # the primary cross spectra to radial processing
  if ( !(-e $sf) ) {

    my $msg = "Source file :: $sf\nEither undefined as an input argument OR the file itself does not exist ... \nERROR! EXITING PROGRAM $0\n";
    $log->write( $msg , 6 ) if ($logit);
    exit;

  }

  my $xfer = HFR::FileTransfer->new_transfer(
					     source_file           => $sf,
                                             remote_host           => $rh,
                                             destination_directory => $dd,
					     ssh_key_file          => $ssh_key,
					     log_file              => $log_file,
					     logit                 => $logit,
					     logger                => $log,
					     queued_directory      => $qd,
					     user                  => $user,
					     verbose               => $verbose,
					     debug                 => $debug );
  $xfer->HFR::FileTransfer::single_push;

  # specific clause for ACORN Icinga
  if ($xfer->{transfer_success}) {

      my $nsca = Net::NSCA::Client->new(
	  encryption_type => 'xor',
	  remote_host     => '137.219.45.12',
	  );

      $nsca->send_report(
	  hostname        => $station,
	  service         => 'ACORN - data transfer',
	  message         => 'OK - data transfer for ' . $sf . ' successful',
	  status          => $Net::NSCA::Client::STATUS_OK,
	  );

  }
}
__END__

=head1 NAME

seasonde_station_date_transfer_push.pl

=head1 SYNOPSIS

This script is intended to 'push' SeaSonde data from a SeaSonde station to a server.

seasonde_station_data_transfer_push.pl --remote_host=<some.server.com> --destination_directory='/remote/data/directory' [options]

=head2 REQUIRED INPUTS

=over 4

=item B<rh|remote_host>

Hostname or IP address of remote host/server to push files onto

=item B<dd|destination_directory>

Directory on remote host/server to push files into

=back

=head2 OPTIONAL INPUTS

=over 4

=item B<sf|source_file>

Full path or just file name of a single file to push

=item B<sd|source_directory>

Path where file(s) exists

=item B<ssh_key_file>

The SSH key file (full path and filename) for automated transfers.  This script
and associated modules will not prompt for a password and will terminate if
password request is encountered.

=item B<user>

Give a username to pass to SSH if logging in as someone other than the user
running this script.

=item B<logit>

Boolean turns on/off logging

=item B<log-file>

Full path and filename of the log file.

=item B<queued>

Boolean turns on/off queuing

=item B<qd|queued_directory>

Full path to directory to list queued files

=item B<ad|archive_directroy>

Full path to directory that contains archives files.  This is for when attempting
to push a queued filename that is no longer in its source directory, because its
been archived.

=item B<v|verbose>

Messages sent to STDOUT as well

=item B<d|debug>

Debug: don't actually transfer or unlink anything

=item B<h|help>

Print this usage message and exit

=back

=head1 REQUIREMENTS

=over 8

=item DateTime

See L<DateTime>

=item Getopt::Long

See L<Getopt::Long>

=item Pod::Usage

See L<Pod::Usage>

=item Log::LogLite

See L<Log::LogLite>

=item Net::NSCA::Client

See L<Net::NSCA::Client>

=item HFR::FileTransfer

See L<HFR::FileTransfer>

=item HFR::YAML

See L<HFR::YAML>

=back

=head1 DESCRIPTION

As this script is mainly a wrapper for the methods of HFR::FileTransfer, which itself loads a HFR ACORN Configuration File, so if the user would like to know more detail information then please see the above module documentation.

This script is called in one of two ways:

=over 4

=item single file transfer

When called with as a single file transfer the script takes one file as the input and attempts to transfer it to a remote location. If it cannot transfer the file for whatever reason, it queues the file name in a separate directory and warns (logs) the monitoring agent (NSCA) that there was a problem. An example might be:
C<seasonde_station_data_transfer_push.pl --sf='/codar/seasonde/data/radials/measpattern/RDLm_BFCV_2012_01_17_0900.ruv' --rh='foo.com' --dd='/foo/incoming/bfcv' -v>

=item queued (multiple or single) file transfer

Whereas if it were being called for a queued file transfer the script looks in a queued directory for files that have a particular extension (default is '*.queued'). For each queued file in that directory the script attempts to transfer the original file to a remote location. Since it is likely that the original file is no longer in it's original location the script then goes off and tries to find the original, hopefully, still on the local computer. The searching is robust but kept to several known local archiving locations. If for some reason the original file cannot be found, the script complain (log this information) and rename the queued file with the extension '.dud'.
Here's an example:
C</seasonde_station_data_transfer_push.pl --queued --sd='/codar/seasonde/data/radials/measpattern' --rh='foo.com' --dd='/foo/incoming/bfcv' -v>


Please see 'perldoc HFR::FileTransfer' for more information

Script uses Net::NSCA::Client for notification of icinga remote monitoring of a successful file transmission

=cut
