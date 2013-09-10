#!/usr/bin/perl
#
# wrapper script for archiving SeaSonde files
#

# define perl state and load modules
use 5.012003;
use strict;
use warnings;
use Getopt::Long;
use HFR::SeaSonde::FileOps;

# initialise and set defaults
my ($sd,$ad);
my $owner        = (caller(0))[3]; #unix equivalent ``whoami''; see perldoc -f caller
my $dir_struct   = 'stymd';
my $verbose      = 0;
my $debug        = 0;
my $file_move    = 0;
my $unlink_found = 0;
my $help_msg     = 0;

# get input options
my $result = GetOptions (
			 "sd|search_directory=s"  => \$sd,
			 "ad|archive_directory=s" => \$ad,
                         "directory_structure=s"  => \$dir_struct,
			 "v|verbose"              => \$verbose,
			 "d|debug"                => \$debug,
			 "file_move"              => \$file_move,
			 "unlink_found_file"      => \$unlink_found,
			 "owner=s"                => \$owner,
                         "h|help!"                => \$help_msg) or usage("Invalid commmand line options.");
# if help requested: print and exit
 usage("$0 HELP") if ( $help_msg );
# search directory invalid or not given
if (!defined $sd or !(-d $sd) ) {
  print "Either the search directory you provided is not valid or you did not supply a search directory\n";
  print "Please provide a valid search directory:\n";
  $sd = <>;
}
# archive base directory not supplied
if (!defined $ad) {
  print "You did not supply an archive base directory which this script requires\n";
  print "Please proved a valid archive base directory:\n";
  $ad = <>;
}

# create new file operation
my $ssr_files = HFR::SeaSonde::FileOps->new_operation(
						      search_directory       => $sd ,
                                                      base_archive_directory => $ad ,
                                                      directory_structure    => $dir_struct ,
						      owner                  => $owner ,
						      verbose                => $verbose ,
						      debug                  => $debug ,
						      file_move              => $file_move ,
						      unlink_found_file      => $unlink_found );

# search for files depending on how many files and sub-directories underneath
# the search directory this can take a bloody long time and a lot of CPU and memory!
$ssr_files->find_files;

# sleep for a few seconds to rest from a possibly big search,
#print "Sleeping for 10 seconds post search ...\n";
#sleep(10); # 10 seconds

# attempt to archive files
$ssr_files->archive_files_from_found_files;

##############################################
sub usage {

  # print input message if any
   my $message = $_[0];
   if (defined $message && length $message) {
     $message .= "\n" unless $message =~ /\n$/;
   }

   # name of the script
   my $command = $0;
   $command =~ s#^.*/##;

   print STDERR (
      $message,
		 "usage: $command --search_directory /my/search/directory --archive_directory /my/archive/directory \ \n".
		 " [--owner owner] [-v|verbose] [-d|debug] [--file_move] [-h|help]\n\n" .
		 "Brief description:\n".
		 "       owner             :: is the name of the owner of the file when moving or copying; default behaviour: result from whoami call\n" .
		 "       verbose           :: turns on printing of messages to STDOUT; default behaviour: verbose on\n" .
		 "       debug             :: prevents any copying or moving files; default behaviour: debug on\n" .
		 "       file_move         :: attempts to move instead of copy; default behaviour: no file moving\n" .
		 "       unlink_found_file :: attempts to remove (delete) the found fle after it is done with it\n".
		 "       help              :: print this message and exit\n\n".
		 "This perl script is intended to be called for organising (copying, moving, shuffling-around)\n".
		 " seasonde data files.\n".
		 "It does some minimal file checking when a file being copied or moved already exists in that\n".
		 " particular location.\n\n".
	         "WARNING: THIS SCRIPT UTILISES HFR::SeaSonde::FileOps MODULE THAT MAKES ASSUMPTION IN COMPARING\n".
		 "         FILES THAT MAY NOT BE WHAT YOU THE USER WOULD LIKE OR ARE INTENDING.  THE AUTHOR\n".
		 "         ENCOURAGES ONE TO AT LEAST READ THE DOCUMENTATION ON THAT MODULE PRIOR TO USE OF THIS\n".
		 "         SCRIPT.\n\n".
		 "This file also uses the default behaviour of HFR::SeaSonde::FileOps , most importantly for the\n".
		 " archive final path it follows this format: /my/archive/data/STATION/DATA_TYPE/YEAR/MONTH/DAY/<FILE>\n".
		 " This is true for all but diagnostic and wave files which are only sub-divided by year.\n\n".
		 "AUTHOR:\n\tDaniel Patrick Atwater\n\tAustralia Coastal Ocan Radar Network\n\tJames Cook University\n\temail: danielpath2o<at>gmail.com\n\n".
		 "VERSION: 2.6\n".
		 "LAST UPDATE: 12 Oct 2012\n".
		 "Please see HFR::SeaSonde-FileOps for more information\n"
		);
   die("\n")
 }
