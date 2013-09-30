#!/usr/bin/perl
#
# seasonde_server_data_transfer_pull.pl
#
# This script uses modules from the Perl HFR (high frequency radar) toolbox.
# Please see accompanying documentation before editing script to suit needs.
#

my $version = 1.3;

################################################################################
# LOAD MODULES/LIBRARIES
use strict;
use Getopt::Long;
use Pod::Usage;
use HFR::SeaSonde::FileOps;
use HFR::SeaSonde::ASCII;
use HFR::FileTransfer;
use Log::LogLite;

use Data::Dumper;

################################################################################
# INITIALISE AND GET INPUTS
my ($help_msg,$verbose);
my $result = GetOptions (
                         "v|verbose!" => \$verbose,
                         "h|help|?"   => \$help_msg
                        );
pod2usage({-verbose => 2, -output => \*STDOUT}) if ($help_msg);

################################################################################
# INTIALISE YAML CONFIG
my $params   = HFR::SeaSonde::FileOps->new_operation();
my @stations = @{$params->{codenames}->{codar_stations}};

################################################################################
# define the current time to be N hours prior to now
my $hours_past   = $params->{time}->{realtime_processing_delay};
my $current_time = time-(3600*$hours_past);

################################################################################
# LOG
my $logit     = $params->{local}->{realtime}->{logit};
my $log_file  = sprintf('%s/seasonde_server_data_transfer_pull.log',$params->{local}->{directories}->{log});
my $log       = new Log::LogLite( $log_file , 0 );

################################################################################
##########################     MAIN PROGRAM    #################################
################################################################################

################################################################################
# loop over each station and retrieve data with HFR::FileTransfer
foreach my $station (@stations) {

  # since Cervantes and Seabird are no longer in operation then we don't need to check them here
  if ( $station =~ /crvt|sbrd/i ) { next; }

  # define the radial directory for a particular station
  my $radial_directory = sprintf('%s%s',$params->{codar}->{directories}->{radial_sites},$station);

  # complain and skip if the radial directory does not exist
  if (!(-d $radial_directory)) {

    my $msg = "Radial Directory :: $radial_directory\ndoes not exist ... \nskipping $0\n";
    $log->write( $msg , 6 ) if ($logit);
    print $msg if ($verbose==1);
    next;

  }

  # default parameters; in case there are no radial files in the local directory
  my $last_radial_file = '';
  my $last_radial_time = time-(3600*24);
  my $table_type       = $params->{local}->{realtime}->{$station}->{table_type};
  my $pattern_type     = $params->{local}->{realtime}->{$station}->{pattern_type};

  # get last radial file and report back the last radial timestamp
  # we do this by opening the realtime radial directory and checking to see if there are any radial files in there at present
  # if there are then we open that file and read its data timestamp
  # if that data timestamp is within one month of current time then retrieve all the files between that radial file and now
  opendir(DIR,$radial_directory) or die "$0:$!\nCannot read $radial_directory\nEnding program!";
  my @tmp_files = grep {/$params->{codar}->{suffixes}->{radial}$/i} readdir(DIR); #get radial files only
  closedir(DIR);

  # if the directory is empty then use the default parameters above and attempt get all the radial files from the previous day
  # otherwise get the last radial file timestamp and file type
  if ($#tmp_files>=0) {

      # sort them by modification date most recent to least recent
      my @sorted = sort {-M "$radial_directory$a" <=> -M "$radial_directory$b"} @tmp_files; 

      # the last file is the file that is the last radial file
      $last_radial_file = $radial_directory.'/'.$sorted[-1];

      # SKIP IF FOUND FILE IS SOMEHOW NOT A RADIAL FILE
      next unless (-f $last_radial_file);

      # Extract the timestamp from the last radial file
      my $radial        = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $last_radial_file );
      my $radial_header = $radial->HFR::SeaSonde::ASCII::get_ascii_header;
      $table_type       = $radial_header->{table_type};
      $pattern_type     = $radial_header->{pattern_type};
      $last_radial_time = HFR::SeaSonde::FileOps::time_string_to_time_number( $radial_header->{time_stamp} );

  }

  # compare last radial time with current time
  # go and get radial if older than two hours
  # since this server has two possible locations where the data are stored then check both
  if ( ($last_radial_time < $current_time-7200) and ($last_radial_time > ($current_time-(3600*24*30))) ) {

      # construct a list of files from last_radial_time to current_time
      my $seasonde = HFR::SeaSonde::FileOps->new_operation(
	                                                   sos                    => $station,
	                                                   start                  => $last_radial_time-3600,
							   stop                   => $current_time-3600,
							   data_type_primary      => $table_type,
							   data_type_secondary    => $pattern_type,
							   base_archive_directory => $params->{acorn}->{base_incoming_directory},
							   directory_structure    => 'symd' );

      $seasonde->construct_file_list;

      # loop over each file and attempt to download file
      foreach my $file (@{$seasonde->{codar}->{fileops}->{full_file_list}}) {

	  my $msg = "Attempting to transfer: $file\nFrom: $params->{acorn}->{hostname}\n";
	  $log->write( $msg , 6 ) if ($logit);
	  print $msg if ($verbose==1);
	  my $xfer = HFR::FileTransfer->new_transfer(
	                                             source_file           => $file,
      					       	     remote_host           => $params->{acorn}->{hostname},
      	 					     destination_directory => $params->{codar}->{directories}->{radial_sites}.$station.'/',
      						     ssh_key_file          => $params->{ssh_key},
      						     log_file              => $log_file,
      						     logit                 => $logit,
      						     logger                => $log,
      						     user                  => $params->{acorn}->{user},
      						     verbose               => $params->{misc}->{verbose},
      						     debug                 => $params->{misc}->{debug} );

	  $xfer->HFR::FileTransfer::single_pull;

      }

      my $seasonde = HFR::SeaSonde::FileOps->new_operation(
	      						   sos                    => $station,
							   start                  => $last_radial_time-3600,
							   stop                   => $current_time-3600,
							   data_type_primary      => $table_type,
							   data_type_secondary    => $pattern_type,
							   base_archive_directory => $params->{acorn}->{base_incoming_directory},
							   directory_structure    => 's' );

      $seasonde->construct_file_list;

      foreach my $file (@{$seasonde->{codar}->{fileops}->{full_file_list}}) {

	  my $msg = "Attempting to transfer: $file\nFrom: $params->{acorn}->{hostname}\n";
	  $log->write( $msg , 6 ) if ($logit);    
	  print $msg if ($verbose==1);
	  my $xfer = HFR::FileTransfer->new_transfer(
	                                             source_file           => $file,
      						     remote_host           => $params->{acorn}->{hostname},
      	 					     destination_directory => $params->{codar}->{directories}->{radial_sites}.$station.'/',
      						     ssh_key_file          => $params->{ssh_key},
      						     log_file              => $log_file,
      						     logit                 => $logit,
      						     logger                => $log,
      						     user                  => $params->{acorn}->{user},
      						     verbose               => $params->{misc}->{verbose},
      						     debug                 => $params->{misc}->{debug} );

	  $xfer->HFR::FileTransfer::single_pull;

      }

  } else {

      my $msg = "Radial file: $last_radial_file is older than 30 days.\nConsider removing file from local realtime directory.\n";
      $log->write( $msg , 6 ) if ($logit);
      print $msg if ($verbose);

  }

}
__END__

=head1 NAME

  Script will attempt to download radial files on the ACORN server in the CODAR Ocean Sensors radial sites directory.
  Used for real-time processing of COS radials into vectors.

=head1 SYNOPSIS

seasonde_server_data_transfer_pull.pl [options]

=head2 OPTIONS

=over 8

=item B<-help>

Print this message and exits.

=item B<-v|verbose>

Print messages about script progress and activities.

=back

=head1 REQUIREMENTS

=over 8

=item Getopt::Long

See L<Getopt::Long>

=item HFR::SeaSonde::FileOps

See L<HFR::SeaSonde::FileOps>

=item HFR::FileTransfer

See L<HFR::FileTransfer>

=item Log::LogLite

See L<Log::LogLite>

=item Pod::Usage;

See L<Pod::Usage>

=back

=head1 DESCRIPTION

  This perl script is intended to be called for pulling SeaSonde radial files from acorn.jcu.edu.au to seasonde.jcu.edu.au

  The program uses the configuration file acorn_perl.yml to extract the necessary information to perform the tast of determining the
      last radial in the CODAR Ocean Sensors radial sites directory and then download files from the remote server and directory on that
      remote server for the particular radar station that are from whenever the last (local) radial file is to the present time.  If there
      no local radial files then the program attempts to get the last days worth of radial files from the remote server.

  This file uses HFR::FileTransfer module and it's associated modules. I encourage you to read the documentation on this module to 
      understand what this script is doing or before modifying this script to suit your needs.

=head1 AUTHOR

  Daniel Patrick Atwater
  L<danielpath2o@gmail.com>

=head1 VERSION

=over 8

=item version 0.1

 30 November 2009
 working version, hastily written with no input arguments and no usage written

=item version 0.2

 17 January 2010
 usage added
 removed Data::Dumper and Term::ANSIColor usages

=item version 1.0

 22 July 2010
 added feature to download radial files even when CODAR radial sites directory is empty

=item version 1.1

 19 February 2012
 added Pod::Usage module and this documentation

=item version 1.2

 08 July 2012
 Using Mac OS X U<launchd> to initialise script. At present 'brute force' loading of libraries from JCU Real-time SeaSonde server as using U<launchd> XML method fails.
 NOTE: this is not the preferred method and alternative approach to hard-wiring directory locations needs to be implemented.

=item version 1.3

 17 September 2013
 Minor changes made to accommodate for changes to acorn_perl.yml file

=back

=head1 COPYRIGHT

Copyright: General Public License (GPL), Daniel Patrick Atwater 2009

=cut



