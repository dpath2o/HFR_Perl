# called from /codar/seasonde/users/scripts/NewTotal to perform appending of grid indices columns
# adapted from matlab fill appendColVec.m
# 
# date: 31 Jan 2013 @ 12:18 UTC
# author: danielpath2o@gmail.com
# version: 1.01
#
# 2013-04-05 : added 1 to grid position output to keep consistent with ACORN netcdf 'POSITION' variable
#
# Things to do:
#   - write usage
#   - clean-up GetOptions
#   - add logging

use strict;
use Data::Dumper;
use Getopt::Long;
use Log::LogLite;
use HFR::SeaSonde::ASCII;
use HFR::SeaSonde::FileOps;
use Date::Calc qw(:all);
use PDL;
use PDL::NiceSlice;

# get input options
my ($file,$site,$verbose,$debug,$help_msg);
my $result = GetOptions (
			 "file=s"    => \$file,
			 "site=s"    => \$site,
			 "v|verbose" => \$verbose,
			 "d|debug"   => \$debug,
                         "h|help!"   => \$help_msg) or usage("Invalid commmand line options.");
usage("HELP MESSAGE:") if ( $help_msg==1 );

# get parameters and define some variables
my $params  = HFR::SeaSonde::FileOps->new_operation( sos => $site );
my $Dbase = $params->{codar}->{directories}->{base};
my $Dconf = $params->{codar}->{directories}->{combineconfigs};
my $Fgrd  = sprintf('%s/combine_%s.grd',$params->{codar}->{directories}->{combine_configs},$site);
my $Dproc = sprintf('%s/processing_%s',$params->{codar}->{directories}->{combine_processing},$site); 
my $Fproc = $Dproc.'/TotalTime.txt';
my $vector_directory = $params->{codar}->{directoreis}->{vectors};

# log
#my $logit    = 1;
#my $log_file = sprintf('%s/seasonde_append_column_to_vector_files.log',$params->{local_server}->{directories}->{log});
#my $log      = new Log::LogLite( $log_file , 0 );

# read vector file header
my $vector = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $file );
$vector->get_ascii_header;
my $data_in = rcols $file, { EXCLUDE => '/^\%/' }, [];

# take care of empty files
if ($data_in->isempty) { $data_in = ones(1,23)*999; }

# read grid file data
my ($grd_x,$grd_y,$grd_flag,$grd_lon,$grd_lat,$grd_x_i,$grd_y_i) = rcols $Fgrd, 0,1,2,3,4,6,7, { LINES => '27:-1' }; 

# intersection
my $dat_lat  = $data_in(:,1)->flat;
my $dat_lon  = $data_in(:,0)->flat;
my $id_grd_x = which( $grd_lat->in($dat_lat) );
my $id_grd_y = which( $grd_lon->in($dat_lon) );
my $id_grd   = intersect( $id_grd_x , $id_grd_y );

# re-organise
my $data_out                            = zeros( $data_in->getdim(0) , $data_in->getdim(1)+4 );
$data_out( : , 1:$data_in->getdim(1) ) .= $data_in;
$data_out( : , $data_in->getdim(1)+1 ) .= $id_grd + 1; # 'POSITION' indices in netcdf file start at 1 and not 0.
$data_out( : , $data_in->getdim(1)+2 ) .= $grd_x_i($id_grd);
$data_out( : , $data_in->getdim(1)+3 ) .= $grd_y_i($id_grd);

# creat output file
my $ts = HFR::SeaSonde::FileOps::time_string_to_time_number( $vector->{time_stamp} );
my ($yr,$mo,$dy, $hr,$mn,$sc, $doy,$dow,$dst) = Localtime( $ts );
my $Ftmp = sprintf('/codar/seasonde/data/processings/totl_%s_%04d_%02d_%02d_%02d00.tuv',$site,$yr,$mo,$dy,$hr);
open( my $fh , '>' , $Ftmp );

# construct/mimic original header
print $fh '%'; printf $fh "CTF:%s" , $vector->{CTF}; 
print $fh '%'; printf $fh "FileType:%s" , $vector->{table_format}; 
print $fh '%'; printf $fh "LLUVSpec:%s" , $vector->{LLUV_spec};
print $fh '%'; printf $fh "UUID:%s" , $vector->{UUID};
print $fh '%'; printf $fh "Manufacturer:%s" , $vector->{manufacturer}; 
print $fh '%'; printf $fh "Site:%s" , $vector->{station_name}; 
print $fh '%'; printf $fh "TimeStamp:%s" , $vector->{time_stamp};
print $fh '%'; printf $fh "TimeZone:%s" , $vector->{time_zone};
print $fh '%'; printf $fh "TimeCoverage:%s" , $vector->{time_coverage};
print $fh '%'; printf $fh "Origin:%s" , $vector->{origin};
print $fh '%'; printf $fh "GreatCircle:%s" , $vector->{great_circle};
print $fh '%'; printf $fh "GeodVersion:%s" , $vector->{geod_version};
print $fh '%'; printf $fh "LLUVTrustData:%s" , $vector->{LLUV_trust_data};

# funny business with double 'GridAxisOrientation' entries in SeaSonde Software Release 7
open(TEXT_FILE,"<$file");
my @lines = <TEXT_FILE>;
close(TEXT_FILE);
my @tmp = grep(/^\%GridAxisOrientation/,@lines);
foreach (@tmp) { print $fh "$_"; }
print $fh '%'; printf $fh "GridCreatedBy:%s" , $vector->{grid_created_by};
print $fh '%'; printf $fh "GridVersion:%s" , $vector->{grid_version};
print $fh '%'; printf $fh "GridTimeStamp:%s" , $vector->{grid_time_stamp};
print $fh '%'; printf $fh "GridLastModified:%s" , $vector->{grid_modified_time};
print $fh '%'; printf $fh "GridAxisType:%s" , $vector->{grid_axis_type};
print $fh '%'; printf $fh "GridSpacing:%s" , $vector->{grid_spacing};
print $fh '%'; printf $fh "AveragingRadius:%s" , $vector->{averaging_radius};
print $fh '%'; printf $fh "DistanceAngularLimit:%s" , $vector->{distance_angular_limit};
print $fh '%'; printf $fh "CurrentVelocityLimit:%s" , $vector->{current_velocity_limit};
print $fh "%TableType: LLUV TOT5\n";

# adjust TableColumns and TableColumnTypes accordingly ... need to make this more general so as to allow for more sites than six
my @dims   = $data_out->dims;
my $N_cols = $dims[1]-1;
print $fh '%'; printf $fh "TableColumns: %s\n" , $N_cols;
if ( $N_cols == 19 ) { 

    print $fh "%TableColumnTypes: LOND LATD VELU VELV VFLG UQAL VQAL CQAL XDST YDST RNGE BEAR VELO HEAD S1CN S2CN GRDN GRDX GRDY\n";

} elsif ( $N_cols == 20 ) { 

    print $fh "%TableColumnTypes: LOND LATD VELU VELV VFLG UQAL VQAL CQAL XDST YDST RNGE BEAR VELO HEAD S1CN S2CN S3CN GRDN GRDX GRDY\n";

} elsif ( $N_cols == 21 ) { 

    print $fh "%TableColumnTypes: LOND LATD VELU VELV VFLG UQAL VQAL CQAL XDST YDST RNGE BEAR VELO HEAD S1CN S2CN S3CN S4CN GRDN GRDX GRDY\n";

} elsif ( $N_cols == 22 ) { 

    print $fh "%TableColumnTypes: LOND LATD VELU VELV VFLG UQAL VQAL CQAL XDST YDST RNGE BEAR VELO HEAD S1CN S2CN S3CN S4CN S5CN GRDN GRDX GRDY\n";

} elsif ( $N_cols == 23 ) { 

    print $fh "%TableColumnTypes: LOND LATD VELU VELV VFLG UQAL VQAL CQAL XDST YDST RNGE BEAR VELO HEAD S1CN S2CN S3CN S4CN S5CN S6CN GRDN GRDX GRDY\n";

}

print $fh '%'; printf $fh "TableRows:%s" , $vector->{table_rows};
print $fh "%TableStart:\n";
print $fh "%%   Longitude   Latitude    U comp   V comp  VectorFlag   U StdDev    V StdDev   Covariance  X Distance  Y Distance   Range   Bearing   Velocity  Direction  Site Contributers Grid Indices\n";

# adjust the units accordingly as well
if ( $N_cols == 19 ) { 

    print $fh "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Quality      (km)        (km)       (km)  (deg NCW)   (cm/s)   (deg NCW)  (#1)(#2)   (N)  (X_N)  (Y_N) \n";

} elsif ( $N_cols == 20 ) { 

    print $fh "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Quality      (km)        (km)       (km)  (deg NCW)   (cm/s)   (deg NCW)  (#1)(#2)(#3)   (N)  (X_N)  (Y_N) \n";

} elsif ( $N_cols == 21 ) { 

    print $fh "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Quality      (km)        (km)       (km)  (deg NCW)   (cm/s)   (deg NCW)  (#1)(#2)(#3)(#4)   (N)  (X_N)  (Y_N) \n";

} elsif ( $N_cols == 22 ) { 

    print $fh "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Quality      (km)        (km)       (km)  (deg NCW)   (cm/s)   (deg NCW)  (#1)(#2)(#3)(#4)(#5)   (N)  (X_N)  (Y_N) \n";

} elsif ( $N_cols == 23 ) { 

    print $fh "%%     (deg)       (deg)     (cm/s)   (cm/s)  (GridCode)    Quality     Quality     Quality      (km)        (km)       (km)  (deg NCW)   (cm/s)   (deg NCW)  (#1)(#2)(#3)(#4)(#5)(#6)   (N)  (X_N)  (Y_N) \n";

}

# write out data ... what about empty files???
if ( $vector->{table_rows} > 1 ) {
    for ( my $l1 = 0; $l1 < $vector->{table_rows}; $l1++ ) {
	wcols $data_out( $l1 , 1:-1 ) , $fh;
    }
}

# construct/mimic original footer
print $fh "%TableEnd:\n%%\n";
open(TXT,"<$file");
while(<TXT>) {
    if (/\%TableType: MRGS*/ .. /\%TableEnd: 2*/) {
	print $fh $_;
   }
}
close(TXT);
print $fh "%%\n%%\n";
print $fh '%'; printf $fh "ProcessedTimeStamp:%s" , $vector->{processed_time_stamp};
print $fh '%'; printf $fh "ProcessingTool: \"Combiner\" %s\n" , $vector->{combiner_version};
print $fh '%'; printf $fh "ProcessingTool: \"CheckForCombine\" %s\n" , $vector->{check_for_combine_version};
print $fh '%'; printf $fh "ProcessingTool: \"TotalArchiver\" %s\n" , $vector->{total_archiver_version};

close($fh); 

#####################################################
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
      "usage: $command\n".
      "\n");
   die("\n")
 }
