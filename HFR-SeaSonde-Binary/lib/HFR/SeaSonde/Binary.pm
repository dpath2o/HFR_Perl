package HFR::SeaSonde::Binary;

use 5.012003;
use strict;
use warnings;
use PDL;
use PDL::IO::FlexRaw;
use PDL::IO::Misc;
use PDL::NiceSlice;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HFR::SeaSonde::Binary ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

###########################################
sub new_binary_file {

  # ESTABLISH THE METHOD
   my($class, %args) = @_;
   my $self          = bless( {} , $class );

  # NAME AND ``GOOD FILE''
   my $full_filename      = exists $args{full_filename} ? $args{full_filename} : '';
   $self->{full_filename} = $full_filename;
   my $file_success        = exists $args{file_success} ? $args{file_success} : 0;
   $self->{file_success}   = $file_success;

   #HEADER
   my $file_test                   = exists $args{file_test} ? $args{file_test} : '';
   $self->{file_test}              = $file_test;
   my $file_size                   = exists $args{file_size} ? $args{file_size} : '';
   $self->{file_size}              = $file_size;
   my $header_size                 = exists $args{header_size} ? $args{header_size} : '';
   $self->{header_size}            = $header_size;
   my $file_version                = exists $args{file_version} ? $args{file_version} : '';
   $self->{file_version}           = $file_version;
   my $file_type                   = exists $args{file_type} ? $args{file_type} : '';
   $self->{file_type}              = $file_type;
   my $station_name                = exists $args{station_name} ? $args{station_name} : '';
   $self->{station_name}           = $station_name;
   my $user_flags                  = exists $args{user_flags} ? $args{user_flags} : '';
   $self->{user_flags}             = $user_flags;
   my $description                 = exists $args{description} ? $args{description} : '';
   $self->{description}            = $description;
   my $owner                       = exists $args{owner} ? $args{owner} : '';
   $self->{owner}                  = $owner;
   my $comment                     = exists $args{comment} ? $args{comment} : '';
   $self->{comment}                = $comment;
   my $ts_1904                     = exists $args{ts_1904} ? $args{ts_1904} : '';
   $self->{ts_1904}                = $ts_1904;
   my $receiver_power_loss         = exists $args{receiver_power_loss} ? $args{receiver_power_loss} : '';
   $self->{receiver_power_loss}    = $receiver_power_loss;
   my $number_of_channels          = exists $args{number_of_channels} ? $args{number_of_channels} : '';
   $self->{number_of_channels}     = $number_of_channels;
   my $number_of_range_cells       = exists $args{number_of_range_cells} ? $args{number_of_range_cells} : '';
   $self->{number_of_range_cells}  = $number_of_range_cells;
   my $number_of_doppler_bins      = exists $args{number_of_doppler_bins} ? $args{number_of_doppler_bins} : '';
   $self->{number_of_doppler_bins} = $number_of_doppler_bins;
   my $IQ_indicator                = exists $args{IQ_indicator} ? $args{IQ_indicator} : '';
   $self->{IQ_indicator}           = $IQ_indicator;
   my $chirp                       = exists $args{chirp} ? $args{chirp} : '';
   $self->{chirp}                  = $chirp;
   my $f0                          = exists $args{f0} ? $args{f0} : '';
   $self->{f0}                     = $f0;
   my $df                          = exists $args{df} ? $args{df} : '';
   $self->{df}                     = $df;
   my $sweep_rate                  = exists $args{sweep_rate} ? $args{sweep_rate} : '';
   $self->{sweep_rate}             = $sweep_rate;
   my $first_range_cell            = exists $args{first_range_cell} ? $args{first_range_cell} : '';
   $self->{first_range_cell}       = $first_range_cell;
   my $data_type                   = exists $args{data_type} ? $args{data_type} : ''; #data type, if 'cviq' the complex voltages I&Q else 'dbrq' the complex power in dBm & phase degrees
   $self->{data_type}              = $data_type;
   my $data_format                 = exists $args{data_format} ? $args{data_format} : ''; # format of range array complex values:
   $self->{data_format}            = $data_format;                                   #                                      'fix2' data is int2 (2byte)
                                                                                     #                                      'fix3' data is int3 (3byte)
                                                                                     #                                      'fix4' data is int4 (4byte)
                                                                                     #                                      'flt4' data is IEEE (4byte)
                                                                                     #                                      'flt8' data is IEEE (8byte)
   #UNIQUE TO CROSS SPECTRA HEADER
   my $cs_kind                            = exists $args{cs_kind} ? $args{cs_kind} : '';
   $self->{cs_kind}                       = $cs_kind;
#   my $cs_type                            = exists $args{cs_type} ? $args{cs_type} : '';
#   $self->{cs_type}                       = $cs_type;
   my $coverage_minutes                   = exists $args{coverage_minutes} ? $args{coverage_minutes} : '';
   $self->{coverage_minutes}              = $coverage_minutes;
   my $delete_source                      = exists $args{delete_source} ? $args{delete_source} : '';
   $self->{delete_source}                 = $delete_source;
   my $override_source                    = exists $args{override_source} ? $args{override_source} : '';
   $self->{override_source}               = $override_source;
   my $sweep_up                           = exists $args{sweep_up} ? $args{sweep_up} : "";
   $self->{sweep_up}                      = $sweep_up;
   my $range_resolution                   = exists $args{range_resolution} ? $args{range_resolution} : '';
   $self->{range_resolution}              = $range_resolution;
   my $output_interval                    = exists $args{output_interval} ? $args{output_interval} : '';
   $self->{output_interval}               = $output_interval;
   my $creator                            = exists $args{creator} ? $args{creator} : '';
   $self->{creator}                       = $creator;
   my $creator_version                    = exists $args{creator_version} ? $args{creator_version} : '';
   $self->{creator_version}               = $creator_version;
   my $number_of_active_channels          = exists $args{number_of_active_channels} ? $args{number_of_active_channels} : '';
   $self->{number_of_active_channels}     = $number_of_active_channels;
   my $number_of_cs_channels              = exists $args{number_of_cs_channels} ? $args{number_of_cs_channels} : '';
   $self->{number_of_cs_channels}         = $number_of_cs_channels;
   my $number_of_active_channel_bits      = exists $args{number_of_active_channel_bits} ? $args{number_of_active_channel_bits} : '';
   $self->{number_of_active_channel_bits} = $number_of_active_channel_bits;
   #DATA
   my $data = exists $args{ssA1} ? $args{ssA1} : ''; #cell matrix that is contains N number of elements where N = dat.nrgs. Each range element will contain 1XM where M = dat.ndps
   $self->{data} = $data;
   #UNIQUE TO CROSS SPECTRA DATA
   my $ssA1      = exists $args{ssA1} ? $args{ssA1} : 0;
   $self->{ssA1} = $ssA1;
   my $ssA2      = exists $args{ssA2} ? $args{ssA2} : 0;
   $self->{ssA2} = $ssA2;
   my $ssA3      = exists $args{ssA3} ? $args{ssA3} : 0;
   $self->{ssA3} = $ssA3;
   my $cs12      = exists $args{cs12} ? $args{cs12} : 0;
   $self->{cs12} = $cs12;
   my $cs23      = exists $args{cs23} ? $args{cs23} : 0;
   $self->{cs23} = $cs23;
   my $cs13      = exists $args{cs13} ? $args{cs13} : 0;
   $self->{cs13} = $cs13;
   my $qc        = exists $args{qc} ? $args{qc} : 0;
   $self->{qc}   = $qc;

   return $self;

}

###########################################
# INSERT A COMMENT
sub comment { 
  my $self = shift;
  if( @_ ) { my $comment = shift; $self->{comment} = $comment; }
  return $self->{comment};
}

##########################################
sub get_time_series_header {
# // Begin File. The first 4bytes should read ʻAQLVʼ 'AQLV' Size32 - This is the first key in the file. All data is inside this key. {
# 'HEAD' Size32 - Data Description Section {
# 'sign' Size32 - File signature
# Fourcc Fourcc Fourcc UInt32 chr64 chr64 chr64
# File version SiteCode FileType UserFlags FileDescription OwnerName Comment
# '1.00' 'XXXX' 'ALVL' 0 "SeaSonde Acquisition Time Series" "CODAR Ocean Sensors Ltd"
# ""
#   'mcda' Size32 - Mac Timestamp UInt32Seconds from Jan 1,1904
# 'cnst' Size32 - Size information
# SInt32 SInt32 SInt32 SInt32
# <nChannels> <nSweeps> <nSamples> IQ Indicator.
# Number of Antennas/Channels (Normally 3) Number of Sweeps Recorded (Normally 32) Number of Samples Per Sweep (Normally 2048) 1 otherwise 2 if sample data is IQ
# 'swep' Size32 - Sweep information
# SInt32 double double double SInt32
# Number of Samples Per Sweep (Normally 2048) Sweep Start Frequency in Hz Sweep Bandwidth in Hz (maybe negative) Sweep Rate in Hz
# RangeCell Offset (Not used) 'fbin' Size32 - Sample Data Type
# of first sweep
#   Fourccformat. Normally 'cviq' indicating complex voltage I & Q
#     FourccType of ʻalvlʼ data (ʻflt4ʼ,ʼfix4ʼ,ʼfix3ʼ,ʼfix2ʼ) } // End of HEAD
# 'BODY' Size32 - This key contains the repeated keys for each sweep recorded. {
  my $self = shift;
  #GET FILE VERSION
  open(BIN_FILE,"<$self->{full_filename}") or die "FATAL ERROR: Cannot open file '$self->{full_filename}' because $!\n";
  binmode(BIN_FILE);
  $self->{version} = unpack 's>', <BIN_FILE>;
  seek(BIN_FILE,0,0);
  #TEMPLATES FOR EACH VERSION
  my $tmpl = 'a4 l> a4 l> a4 l> a4 a4 a4 L> a64 a64 a64 a4 l> L> a4 l>5 a4 l>2 d>3 l> a4 l> a4 a4';
  #PULL OUT HEADER INFORMATION DEPENDING ON WHICH VERSION
  my @hdr = unpack $tmpl, <BIN_FILE>;
  close(BIN_FILE);
  #ASSIGN HEADER TO RESPECTIVE ASSOCIATIVE ARRAY ELEMENTS
  if ($#hdr >= 32) {
    $self->{file_success}        = 1;
    $self->{file_test}           = $hdr[0];
    $self->{file_size}           = $hdr[1];
    $self->{header_size}         = $hdr[3];
    $self->{file_version}        = $hdr[6];
    $self->{file_type}           = $hdr[7]; # COS documentation has still got these next two items incorrectly swapped
    $self->{station_name}        = $hdr[8]; # $hdr[7] is listed as SiteCode in the documentation
    $self->{user_flags}          = $hdr[9];
    $self->{description}         = $hdr[10];
    $self->{owner}               = $hdr[11];
    $self->{comment}             = $hdr[12];
    $self->{ts_1904}             = $hdr[15];
    $self->{number_of_channels}  = $hdr[18];
    $self->{number_of_sweeps}    = $hdr[19];
    $self->{number_of_samples}   = $hdr[20];
    $self->{IQ_indicator}        = $hdr[21];
    $self->{chirp}               = $hdr[24];
    $self->{f0}                  = $hdr[25];
    $self->{df}                  = $hdr[26];
    $self->{sweep_rate}          = $hdr[27];
    $self->{first_range_cell}    = $hdr[28];
    $self->{data_type}           = $hdr[31];
    $self->{data_format}         = $hdr[32];
  }

  return $self;

}

##################################################
sub get_range_series_header {
# // Begin File. The first 4bytes should read ʻAQFTʼ 'AQFT' Size32 - This is the first key in the file. All data is inside this key.
#   {
# 'HEAD' Size32 {
#   'sign' Size32// File Signature
#     UInt32nFileVersion// file code
# '1.00' // file type
# UInt32 UInt32 UInt32 Char[64] Char[64] Char[64] 'mcda' Size32 UInt32
# ʻdbrfʼ Size32 Double
# 'cnst' Size32 SInt32
# SInt32 SInt32 SInt32 'swep' Size32 SInt32 Double Double Double SInt32
# 'fbin' Size32 Fourcc
# nFileType nOwner// ownertype nUserFlags szFileName szOwnerName szComment
# 'AQFT'
# if 'cviq' then data is complex Voltages I, Q if 'dbra' then data is complex Power dBm, Phase Deg
#   FourccFormat Of Range Array complex Values if 'fix2' then data is of integer (2byte) use 'scal' to adjust if 'fix3' then data is of integer (3byte) use 'scal' to adjust if 'fix4' then data is of integer (4byte) use 'scal' to adjust if 'flt4' then data is of IEEE (4byte) floating point if 'flt8' then data is of IEEE (8byte) floating point
# } 'BODY' Size32
  my $self = shift;
  #GET CS FILE VERSION
  open(BIN_FILE,"<$self->{full_filename}") or die "FATAL ERROR: Cannot open file '$self->{full_filename}' because $!\n";
  binmode(BIN_FILE);
  $self->{version} = unpack 's>', <BIN_FILE>;
  seek(BIN_FILE,0,0);
  #TEMPLATES FOR EACH VERSION
  my $tmpl = 'a4 l> a4 l> a4 l> a4 a4 a4 a4 a64 a64 a64 a4 l> L> a4 l> d> a4 l>5 a4 l>2 d>3 l> a4 l> a4 a4';
  #PULL OUT HEADER INFORMATION DEPENDING ON WHICH VERSION
  my @hdr = unpack $tmpl, <BIN_FILE>;
  close(BIN_FILE);
  #ASSIGN HEADER TO RESPECTIC ASSOCIATIVE ARRAY
  if ($#hdr >= 35) {
    $self->{file_success}           = 1;
    $self->{file_test}              = $hdr[0];
    $self->{file_size}              = $hdr[1];
    $self->{header_size}            = $hdr[3];
    $self->{file_version}           = $hdr[6];
    $self->{file_type}              = $hdr[7];
    $self->{station_name}           = $hdr[8];
    $self->{user_flags}             = $hdr[9];
    $self->{description}            = $hdr[10];
    $self->{owner}                  = $hdr[11];
    $self->{comment}                = $hdr[12];
    $self->{ts_1904}                = $hdr[15];
    $self->{receiver_power_loss}    = $hdr[18];
    $self->{number_of_channels}     = $hdr[21];
    $self->{number_of_range_cells}  = $hdr[22];
    $self->{number_of_doppler_bins} = $hdr[23];
    $self->{IQ_indicator}           = $hdr[24];
    $self->{chirp}                  = $hdr[27];
    $self->{f0}                     = $hdr[28];
    $self->{df}                     = $hdr[29];
    $self->{sweep_rate}             = $hdr[30];
    $self->{first_range_cell}       = $hdr[31];
    $self->{data_type}              = $hdr[34];
    $self->{data_format}            = $hdr[35];
  }
  return $self;

}

################################################
sub get_cross_spectra_header {
###################################
# BINARY FILE TEMPLATE:
#
#    * They have a variable size header section followed by the cross spectra products.
#    * The data uses Big-Endian byte ordering (Most Significant Byte first. This means that on Intel platforms, you will need to swap the byte order for the variable being read.)
#    * IEEE floating point values single (4bytes) and double (8byte precision).
#    * Twoʼs complement, integer values.
#   
#   Data Type Definitions:
#      * Uint8   : Unsigned 8bit integer
#      * Sint8   : Signed 8bit integer
#      * Uint16  : Unsigned 16bit integer
#      * Sint16  : Signed 16bit integer
#      * Uint32  : Unsigned 32bit integer
#      * Sint32  : Signed 32bit integer
#      * Uint64  : Unsigned 64bit integer
#      * Sint64  : Signed 64bit integer
#      * Float   : IEEE single precision floating point number (4bytes)
#      * Double  : IEEE double precision floating point number (8bytes)
#      * Size4   : Unsigned 32bit integer indicating the size of following data
#      * Char4   : Four character code (meaning that the next four bytes make a four character string)
#      * Char8   : 8byte string zero terminated (zero fill to get 8bytes max. must have at least one zero)
#      * Char32  : 32byte string zero terminated (zero fill to get max. must have at least one zero)
#      * Char64  : 64byte string zero terminated (zero fill to get max. must have at least one zero)
#      * Char256 : 256byte string zero terminated (zero fill to get max. must have at least one zero)
#      * Complex : 2 IEEE single precision floating point numbers of real and imag pairs (8bytes, 4bytes each float)
#  
#  HEADER: 
#   Each File has two major sections. A Header section and a Data section. The Header section is as follows:
#      - The header is expandable. Each newer version also contains the information used the by older version.
#      - When reading a CrossSpectra file that is a newer version than you expect then use the Extent field to skip to the beginning of the cross spectra data.
#      - The following Header description is a set of data fields in order where each field description is a value type with implied size, followed by the field name, and followed by the fieldʼs description.
#    * Note. If version is 3 or less, then nRangeCells=31, nDopplerCells=512, nFirstRangeCell=1
#
#    Version 1:
#      * SInt16 -> nCsaFileVersion -> File Version 1 to latest. (If greater than 32, itʼs probably not a spectra file.)
#      * UInt32 -> nDateTime -> TimeStamp. Seconds from Jan 1,1904 local computer time at site. The timestamp for CSQ files represents the start time of the data (nCsaKind = 1). The timestamp for CSS and CSA files is the center time of the data (nCsaKind = 2).
#      * SInt32 -> nV1Extent -> Header Bytes extension (Version 4 is +62 Bytes Till Data) 
#
#    Version 2:
#      * SInt16 -> nCsKind -> Type of CrossSpectra Data. 1 is self spectra for all used channels, followed by cross spectra. Timestamp is start time of data. 2 is self spectra for all used channels, followed by cross spectra, followed by quality data. Timestamp is center time of data.
#      * SInt32 -> nV2Extent -> Header Bytes extension (Version 4 is +56 Bytes Till Data)
#
#    Version 3:
#      * Char4  -> nSiteCodeName -> Four character site code 'site'
#      * SInt32 -> nV3Extent -> Header Bytes extension (Version 4 is +48 Bytes Till Data)
#   
#    Version 4:
#      * SInt32 -> nCoverageMinutes -> Coverage Time in minutes for the data. ʻCSQ' is normally 5minutes (4.5 rounded). 'CSS' is normally 15minutes average. 'CSA' is normally 60minutes average.
#      * SInt32 -> bDeletedSource -> Was the ʻCSQ' deleted by CSPro after reading.
#      * SInt32 -> bOverrideSourceInfo -> If not zero, CSPro used its own preferences to override the source ʻCSQʼ spectra sweep settings.
#      * Float  -> fStartFreqMHz -> Transmit Start Freq in MHz
#      * Float  -> fRepFreqHz -> Transmit Sweep Rate in Hz
#      * Float  -> fBandwidthKHz -> Transmit Sweep bandwidth in kHz
#      * SInt32 -> bSweepUp -> Transmit Sweep Freq direction is up if non zero, else down. NOTE: CenterFreq is fStartFreqMHz + fBandwidthKHz/2 * -2^(bSweepUp==0)
#      * SInt32 -> nDopplerCells -> Number of Doppler Cells (nominally 512)
#      * SInt32 -> nRangeCells -> Number of RangeCells (nominally 32 for ʻCSQ', 31 for 'CSS' & 'CSA')
#      * SInt32 -> nFirstRangeCell -> Index of First Range Cell in data from zero at the receiver. ʻCSQ' files nominally use zero. 'CSS' or 'CSA' files nominally use one because CSPro cuts off the first range cell as meaningless.
#      * Float  -> fRangeCellDistKm -> Distance between range cells in kilometers.
#      * SInt32 -> nV4Extent -> Header Bytes extension (Version 4 is +0 Bytes Till Data)
#
#    Version 5:
#      * SInt32 -> nOutputInterval -> The Output Interval in Minutes.
#      * Char4  -> nCreatorTypeCode -> The creator application type code.
#      * Char4  -> nCreatorVersion -> The creator application version.
#      * SInt32 -> nActiveChannels -> Number of active antennas
#      * SInt32 -> nSpectraChannels -> Number antenna used in cross spectra
#      * UInt32 -> nActiveChannelBits -> Bit indicator of which antennas are in use msb is ant#1 to lsb #32
#      * SInt32 -> nV5Extent -> Header Bytes extension (Version 5 is +0 Bytes Till Data) If zero then cross spectra data follows, but if this file were version 6 or greater then the nV5Extent would tell you how many more bytes the version 6 and greater uses until the data.

  my $self = shift;
  #GET CS FILE VERSION
  open(BIN_FILE,"<$self->{full_filename}") or die "FATAL ERROR: Cannot open file '$self->{full_filename}' because $!\n";
  binmode(BIN_FILE);
  $self->{file_version} = unpack 's>', <BIN_FILE>;
  seek(BIN_FILE,0,0);
  #TEMPLATES FOR EACH VERSION
  my $tmpl1 = 's> L> l>';
  my $tmpl2 = 's> L> l> s> l>';
  my $tmpl3 = 's> L> l> s> l> a4 l>';
  my $tmpl4 = 's> L> l> s> l> a4 l>4 f>3 l>4 f> l> f>*';
  my $tmpl5 = 's> L> l> s> l> a4 l>4 f>3 l>4 f> l>2 a4 a4 l>2 L> l> f>*';

  my @hdr;
  #PULL OUT HEADER INFORMATION DEPENDING ON WHICH VERSION
  if ($self->{file_version} =~ /1/) {
    @hdr                 = unpack $tmpl1, <BIN_FILE>;
    if ($#hdr >= 1) {
      $self->{file_success} = 1;
      $self->{header_size}  = 10;
      $self->{cs_kind}      = $hdr[0];
      $self->{ts_1904}      = $hdr[1];
    }
  } elsif ($self->{file_version} =~ /2/) {
    @hdr                 = unpack $tmpl2, <BIN_FILE>;
    if ($#hdr >= 3) {
      $self->{file_success} = 1;
      $self->{header_size}  = 16;
      $self->{cs_kind}      = $hdr[0];
      $self->{ts_1904}      = $hdr[1];
      $self->{file_type}      = $hdr[3];
    }
  } elsif ($self->{file_version} =~ /3/) {
    @hdr                  = unpack $tmpl3, <BIN_FILE>;
    if ($#hdr >= 5) {
      $self->{file_success} = 1;
      $self->{header_size}  = 24; 
      $self->{cs_kind}      = $hdr[0];
      $self->{ts_1904}      = $hdr[1];
      $self->{file_type}      = $hdr[3];
      $self->{station_name} = $hdr[5];
    }
  } elsif ($self->{file_version} =~ /4/) {
    @hdr                            = unpack $tmpl4, <BIN_FILE>;
    if ($#hdr >= 17) {
      $self->{file_success}           = 1;
      $self->{header_size}            = 84;
      $self->{cs_kind}                = $hdr[0];
      $self->{ts_1904}                = $hdr[1];
      $self->{file_type}                = $hdr[3];
      $self->{station_name}           = $hdr[5];
      $self->{coverage_minutes}       = $hdr[7];
      $self->{delete_source}          = $hdr[8];
      $self->{override_source}        = $hdr[9];
      $self->{f0}                     = $hdr[10];
      $self->{sweep_rate}             = $hdr[11];
      $self->{df}                     = $hdr[12];
      $self->{sweep_up}               = $hdr[13];
      $self->{number_of_doppler_bins} = $hdr[14];
      $self->{number_of_range_cells}  = $hdr[15];
      $self->{first_range_cell}       = $hdr[16];
      $self->{range_resolution}       = $hdr[17];
    }
  } elsif ($self->{file_version} =~ /5/) {
    @hdr                                   = unpack $tmpl5, <BIN_FILE>;
    if ($#hdr >= 24) {
      $self->{file_success}                  = 1;
      $self->{header_size}                   = 100;
      $self->{cs_kind}                       = $hdr[0];
      $self->{ts_1904}                       = $hdr[1]; 
      $self->{file_type}                       = $hdr[3];
      $self->{station_name}                  = $hdr[5];
      $self->{coverage_minutes}              = $hdr[7];
      $self->{delete_source}                 = $hdr[8];
      $self->{override_source}               = $hdr[9];
      $self->{f0}                            = $hdr[10];
      $self->{sweep_rate}                    = $hdr[11];
      $self->{df}                            = $hdr[12];
      $self->{sweep_up}                      = $hdr[13];
      $self->{number_of_doppler_bins}        = $hdr[14];
      $self->{number_of_range_cells}         = $hdr[15];
      $self->{first_range_cell}              = $hdr[16];
      $self->{range_resolution}              = $hdr[17];
      $self->{output_interval}               = $hdr[19];
      $self->{creator}                       = $hdr[20];
      $self->{creator_version}               = $hdr[21];
      $self->{number_of_active_channels}     = $hdr[22];
      $self->{number_of_cs_channels}         = $hdr[23];
      $self->{number_of_active_channel_bits} = $hdr[24];
    }
  }
  close(BIN_FILE);

  return $self;

}


#################################################
sub get_time_series_data {
# } // End of HEAD
# 'BODY' Size32 - This key contains the repeated keys for each sweep recorded. { It normally contains a list of 'indx','scal','alvl' keys for each sweep.
# 'indx' Size32 - This key helps to index the current sweep. SInt32Sweep Index from zero to <nSweeps>-1
# 'scal' Size32 - This key tells how to scale following 'alvl' sample data to get voltage. doubleScalarOneI scale value. doubleScalarTwoQ scale value.
# 'alvl' Size32 - The sample data for a single sweep Array of SInt16 of IQ pairs <nSamples> long.
# <ISample#0><QSample#0><ISample#1><QSample#1>....
# <ISample#(nSamples-1)><QSample#(nSamples-1)> } // Repeat these keys for each sweep. End Of BODY
# } End of AQVL 'END ' Size32 - End of File key // End Of File
}

##############################################
sub get_range_series_data {
# 'BODY' Size32
#   {
#     'CDAR' // whatever0 // "SeaSondeAcquisition" // "CODAR Ocean Sensors Ltd" // whatever
#       // Data Time Stamp nDateTime// MacOS seconds from 1904
# Receiver Power loss reference in dB. Adding this should give roughly dBm. // Data Sizes
# Number Channels Number Range Cells Number Doppler Cells 1 source was I only, 2 source was I&Q // Acquired from SeaSondeController App Samples Per Sync
# Start Freq in Hz BandWidth in Hz Sweep Rate in Hz Start Range Bin from orig FFT (zero based)
# // Type of data Type of Data ['cviq','dbra']
# // The following keys are repeated for each Range Series up to the number of DopplerCells. // The ʻindxʼ key will always precede the ʻafftʼ key // the data format of ʻafftʼ is determined by previous 'fbin' key
#   'rtag' Size32 // Repeater Posistion Tag (Optional Key) UInt32Bearing to Repeater degrees
# 'gps1' Size32 // GPS Tag (Optional Key)
# 'indx' Size32 SInt32
# Double Double Double SInt32
# Latitude in Radians Longitude in Radians Altitude in Meters TimeStamp
# Current RangeSeries index number 0 to (DopplerCells - 1) 'scal' Size32 Data Scalar for following ʻafftʼ key contents
#   DoubleData Scalar for complex real component
#     DoubleData Scalar for complex imaginary component 'afft' Size32 Range Array
# // Array Size is (row, col) or [Channels] by [RangeCells] of
# // Complex real, imag pairs. 'ifft' Size32 Range Array Negative frequencies. (Optional Key)
# // Contains the image freq of the FFT in reverse order
# // 'afft' rangecell 0 corrisponds to 'ifft' rangecell (RangeCells-1) // Array Size is (row,col) [Channels] by [RangeCells] of // Complex real,imag pairs
#   // Repeat of previous keys for number of DopplerDells 'END' Size32// zero size key indicating of range series
# } // End Of File
  my $self = shift;
  #open file and seek past header
  open(BIN_FILE,'<',$self->{full_filename});
  binmode(BIN_FILE);
  seek(BIN_FILE,$self->{hdr_size}+16,0);

  my @tmp = unpack 'a4 l> a4 l>2 a4 l>', <BIN_FILE>; 
  #loop over number Doppler cell
  for (my $i=0; $i<$self->{number_of_doppler_bins}; $i++) {
    # range seires data
    $self->{afft} = readflex( \*BIN_FILE , [ {Type=>'swap'}, { Type=>'float' , NDims=>1 , Dims=>[$self->{number_of_channels},$self->{number_of_range_cells}] } ]  );
  }
  close(BIN_FILE);

  return $self;

}

######################################################
sub get_cross_spectra_data {
#
#  DATA:
#    The data section is a multi-dimensional array of self and cross spectra data.
#    Repeat For 1 to nRangeCells:
#      * Float[nDopplerCells] Antenna1 voltage squared amplitude self spectra.
#      * Float[nDopplerCells] Antenna2 voltage squared amplitude self spectra.
#      * Float[nDopplerCells] Antenna3 voltage squared amplitude self spectra.
#        (Warning: Some Antenna3 amplitude values may be negative to indicate noise or interference at those doppler bins. These negative values should be absoluted before use.)
#      * Complex[nDopplerCells] Antenna 1 to Antenna 2 cross spectra.
#      * Complex[nDopplerCells] Antenna 1 to Antenna 3 cross spectra.
#      * Complex[nDopplerCells] Antenna 2 to Antenna 3 cross spectra.
#    if nCsaKind is 2 then also read or skip
#      * Float[nDopplerCells] Quality array from zero to one in value.
#    End Repeat
#
# Note: To convert self spectra to dBm use:
#       10*log10(abs(voltagesquared)) - (-40. + 5.8)
#       The -40. is conversion loss in the receiver and +5.8 is processing computational gain.
  my $self = shift;

  open(CS,'<',$self->{full_filename});
  binmode(CS);

  for (my $i=0; $i<$self->{number_of_range_cells}; $i++) {

    # seek to appropriate position in file
    if ($i>0) {
      seek(CS,$self->{hdr_sze}*$self->{number_of_doppler_bins}*9*4,0);
    } else {
      seek(CS,$self->{hdr_sze},0);
    }

    # self-spectra antenna 1
    $self->{ssA1} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'float' , NDims=>1 , Dims=>[$self->{number_of_doppler_bins}] } ]  );
    # self-spectra antenna 2
    $self->{ssA2} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'float' , NDims=>1 , Dims=>[$self->{number_of_doppler_bins}] } ]  );
    # self-spectra antenna 3
    $self->{ssA3} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'float' , NDims=>1 , Dims=>[$self->{number_of_doppler_bins}] } ]  );
    # cross-spectra antenna 1 to 2
    $self->{cs12} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'double' , NDims=>2 , Dims=>[$self->{number_of_doppler_bins},2] } ]  );
    # cross-spectra antenna 2 to 3
    $self->{cs23} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'double' , NDims=>2 , Dims=>[$self->{number_of_doppler_bins},2] } ]  );
    # cross-spectra antenna 1 to 3
    $self->{cs13} = readflex( \*CS , [ {Type=>'swap'}, { Type=>'double' , NDims=>2 , Dims=>[$self->{number_of_doppler_bins},2] } ]  );
    # quality-control
    $self->{qc}   = readflex( \*CS , [ {Type=>'swap'}, { Type=>'float' , NDims=>1 , Dims=>[$self->{number_of_doppler_bins}] } ]  );

  }
  close(CS);

  return $self;

}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HFR::SeaSonde::Binary - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HFR::SeaSonde::Binary;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HFR::SeaSonde::Binary, created by h2xs. It looks like the
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

Daniel Atwater, E<lt>dpath2o@macosforge.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Daniel Atwater

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
