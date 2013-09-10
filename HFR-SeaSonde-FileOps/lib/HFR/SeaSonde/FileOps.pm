package HFR::SeaSonde::FileOps;

use 5.012003;
use strict;
# STANDARD PACKAGES
use File::Basename;
use File::Compare;
use File::Path qw(make_path);
use File::Copy;
use File::Find;
use File::stat;
# THIRD PARTY PACKAGES
use Data::Dumper;
use DateTime;
use DateTime::Event::Recurrence;
use DateTime::Format::Epoch::MacOS;
use DateTime::Format::Strptime;
use Date::Calc qw(:all);
use YAML::XS qw(LoadFile);
use Scalar::Util qw(looks_like_number);
# HFR PACKAGES
use HFR;
use HFR::SeaSonde::ASCII;
use HFR::SeaSonde::Binary;

our $VERSION = '1.23';

################################################################################`
sub new_operation {

   my($class, %args) = @_;
   my $self          = bless( {} , $class );


   # load configuration file and bless to self
   my $config_file = exists $args{config_file} ? $args{config_file} : $ENV{"HOME"}.'/acorn_perl.yml';
   $self           = LoadFile $config_file;

   # INPUTS
   my $sos                                          = exists $args{sos} ? $args{sos} : $self->{codenames}->{sos};
   $self->{codenames}->{sos}                        = $sos;
   my $start                                        = exists $args{start} ? $args{start} : $self->{time}->{start};
   $self->{time}->{start}                           = $start;
   my $stop                                         = exists $args{stop} ? $args{stop} : $self->{time}->{stop};
   $self->{time}->{stop}                            = $stop;
   my $dt                                           = exists $args{dt} ? $args{dt} : $self->{time}->{dt};
   $self->{time}->{dt}                              = $dt;
   my $search_directory                             = exists $args{search_directory} ? $args{search_directory} : $self->{codar}->{directories}->{search}; 
   $self->{codar}->{directories}->{search}          = $search_directory;
   my $base_archive_directory                       = exists $args{base_archive_directory} ? $args{base_archive_directory} : $self->{codar}->{directories}->{base_archive};
   $self->{codar}->{directories}->{base_archive}    = $base_archive_directory;
   my $archive_types                                = exists $args{archive_types} ? $args{archive_types} : $self->{codar}->{fileops}->{archive_types};
   $self->{codar}->{fileops}->{archive_types}       = $archive_types;
   my $data_type_primary                            = exists $args{data_type_primary} ? $args{data_type_primary} : $self->{codar}->{fileops}->{data_type_primary};
   $self->{codar}->{fileops}->{data_type_primary}   = $data_type_primary;
   my $data_type_secondary                          = exists $args{data_type_secondary} ? $args{data_type_secondary} : $self->{codar}->{fileops}->{data_type_secondary};
   $self->{codar}->{fileops}->{data_type_secondary} = $data_type_secondary;
   my $directory_structure                          = exists $args{directory_structure} ? $args{directory_structure} : $self->{codar}->{fileops}->{directory_sturcture};
   $self->{codar}->{fileops}->{directory_structure} = $directory_structure;
   my $file_move                                    = exists $args{file_move} ? $args{file_move} : $self->{codar}->{fileops}->{move};
   $self->{codar}->{fileops}->{move}                = $file_move;
   my $unlink_found_file                            = exists $args{unlink_found_file} ? $args{unlink_found_file} : $self->{codar}->{fileops}->{unlink_found_file};
   $self->{codar}->{fileops}->{unlink_found_file}   = $unlink_found_file;
   my $unlink_archive_file                          = exists $args{unlink_archive_file} ? $args{unlink_archive_file} : $self->{codar}->{fileops}->{unlink_archive_file};
   $self->{codar}->{fileops}->{unlink_archive_file} = $unlink_archive_file;
   my $owner                                        = exists $args{owner} ? $args{owner} : $self->{local_server}->{user};
   $self->{local_server}->{user}                    = $owner;
   my $debug                                        = exists $args{debug} ? $args{debug} : $self->{misc}->{debug};
   $self->{misc}->{debug}                           = $debug;
   my $verbose                                      = exists $args{verbose} ? $args{verbose} : $self->{misc}->{verbose};
   $self->{misc}->{verbose}                         = $verbose;

   # RETURN
   bless $self;
   return $self;

}
################################################################################
sub read_radial_header_file {

}
################################################################################
sub construct_file_list {

  my $self = shift;

  # parse the datetime inputs
  $self->HFR::determine_datetime;

  # if ascii then ...
  unless ( $self->{codar}->{fileops}->{data_type_primary} ~~ qw( cs ts rs spectra range_series time_series ) ) {

    # determine data type
    $self->file_parts_from_ascii_table_type_and_config_file( $self->{codar}->{fileops}->{data_type_primary} , $self->{codar}->{fileops}->{data_type_secondary} );

    # put times into a more usable format
    my($yr0,$mo0,$md0, $hr0,$mn0,$sc0, $doy0,$dow0,$dst0) = Localtime( $self->{time}->{start} );
    my($yrN,$moN,$mdN, $hrN,$mnN,$scN, $doyN,$dowN,$dstN) = Localtime( $self->{time}->{stop} );

    unless ( $self->{codar}->{fileops}->{type} ~~ qw ( stat wvlm ) ) { #RADIALS

        # radials
        # zero-out minute and second
        # this is right ... should be dependent upon configuration file
        $self->{time}->{start} = Mktime( $yr0,$mo0,$md0, $hr0,0,0 );
        $self->{time}->{stop}  = Mktime( $yrN,$moN,$mdN, $hrN,0,0 );

        # loop over each time and output file list
        for (my $t = $self->{time}->{start}; $t <= $self->{time}->{stop}; $t=$t+$self->{time}->{dt}) {

            $self->{codar}->{fileops}->{file_time_stamp} = $t;
            $self->construct_archive_directory;
            $self->construct_full_filename;
            push @{$self->{codar}->{fileops}->{full_file_list}} , $self->{codar}->{fileops}->{full_filename} ;

        }

    } elsif ( $self->{codar}->{fileops}->{type} ~~ qw( stat ) ) { #DIAGNOSTICS

        # diagnostics ... a bit more complex
        # zero-out hour, minute and second and go to previous Sunday
        my $sunday = 7;
        my $dt     = DateTime::Event::Recurrence->weekly( days => 7 );
        my $t0     = DateTime->new(year => $yr0, month => $mo0, day => $md0);
        $t0->subtract(days => ($t0->day_of_week - $sunday) % 7);
        my $tN     = DateTime->new(year => $yrN, month => $moN, day => $mdN);
        $tN->subtract(days => ($t0->day_of_week - $sunday) % 7);
        my @ts     = $dt->as_list( start => $t0 , end => $tN );

        # loop over each time and output file list
        foreach (@ts) {

            my $t = Mktime( $_->year() , $_->month(), $_->day() , 0,0,0 );
            $self->{codar}->{fileops}->{file_time_stamp} = $t;
            $self->construct_archive_directory;
            $self->construct_full_filename;
            push @{$self->{codar}->{fileops}->{full_file_list}} , $self->{codar}->{fileops}->{full_filename} ;

        }

    } else { #MUST BE WAVES

        my $dt     = DateTime::Event::Recurrence->monthly( days => 1 );
        my $t0     = DateTime->new( year => $yr0, month => $mo0, day => $md0 );
        my $t0_mdN = DateTime->last_day_of_month( year => $yr0, month => $mo0, day => $md0 );
        $t0->subtract(days => ($t0->day - $t0_mdN) % $t0_mdN);
        my $tN     = DateTime->new(year => $yrN, month => $moN, day => $mdN);
        my $tN_mdN = DateTime->last_day_of_month( year => $yrN, month => $moN, day => $mdN );
        $tN->subtract(days => ($tN->day - $tN_mdN) % $tN_mdN);
        my @ts     = $dt->as_list( start => $t0 , end => $tN );

        # loop over each time and output file list
        foreach (@ts) {

            my $t = Mktime( $_->year() , $_->month(), $_->day() , 0,0,0 );
            $self->{codar}->{fileops}->{file_time_stamp} = $t;
            $self->construct_archive_directory;
            $self->construct_full_filename;
            push @{$self->{codar}->{fileops}->{full_file_list}} , $self->{codar}->{fileops}->{full_filename} ;

        }

    }

  } else { # binary data

    # determine delta time ???

    # determine data type

  }

  return $self;

}
################################################################################
sub find_files {

  my $self = shift;

  print "\n\nSearching $self->{codar}->{directories}->{search} directory for SeaSonde files ... " if $self->{misc}->{verbose};
  find( \&FINDFILES , $self->{codar}->{directories}->{search} );
  print "found $#{$self->{codar}->{filepops}->{found_files}} files\n\n" if $self->{misc}->{verbose};

  sub FINDFILES { #SITE_TYPE_YY[YY]_MO[_HRMN|_HRMNSC]?.[xx|xxx]

    if ($_ =~ m/^(\w{3}|\w{4})[_](\w{4})[_](\d{4}|\d{2})[_](\d{2})[_](\d{2})[_]?(\d{2})?(\d{2})?(\d{2})?[.]?(\w{3}|\w{4})?/i) {

      push @{$self->{codar}->{filepops}->{found_files}}, $File::Find::name;

    }

  }

}
################################################################################
sub parse_filename {

  my $self     = shift;
  my $fullfile = shift;
  my @sufs     = @{$self->{codar}->{suffixes}->{all}};
  my($file,$path,$suffix) = fileparse( $fullfile , @sufs );

  if ($file =~ m/^(\w{3}|\w{4})[_](\w{4})[_](\d{4}|\d{2})[_](\d{2})[_](\d{2})[_]?(\d{2})?(\d{2})?(\d{2})?[.]?(\w{3}|\w{4})?/i) {

    my $Fty=lc($1); 
    my $Fsi=lc($2); 
    my $Fyr=$3;
    my $Fmo=$4;
    my $Fmd=$5;
    my $Fhr=$6;
    my $Fmn=$7;
    my $Fsc=$8;

    # deal with change in century if the year is 2 digit
    $Fyr+=1900 if $Fyr>=90 && $Fyr<=100; #only good to 2090 
    $Fyr+=2000 if $Fyr<90  && $Fyr;

    return ($Fty,$Fsi,$Fyr,$Fmo,$Fmd,$Fhr,$Fmn,$Fsc);

  }

}
################################################################################
sub time_seconds_from_1904_to_time_number {

  my $self    = shift;
  my $time_in = shift;

  # my $t_base  = DateTime->new(
  #       		      year      => $self->{time}->{DateTime}->{year}, #1904,
  #       		      month     => $self->{time}->{DateTime}->{month}, #1,
  #       		      day       => $self->{time}->{DateTime}->{day}, #1,
  #       		      hour      => $self->{time}->{DateTime}->{hour}, #0,
  #       		      minute    => $self->{time}->{DateTime}->{minute}, #0,
  #       		      second    => $self->{time}->{DateTime}->{second}, #0,
  #       		      time_zone => $self->{time}->{DateTime}->{zone}, #'UTC',
  #       		     );

  # my $tmp = DateTime::Format::Epoch::MacOS->new(
  #       					epoch             => $t_base,
  #       					unit              => $self->{time}->{DateTime}->{Epoch}->{unit}, #'seconds',
  #       					type              => $self->{time}->{DateTime}->{Epoch}->{type}, #'int', # or 'float', 'bigint'
  #       					skip_leap_seconds => $self->{time}->{DateTime}->{Epoch}->{skip_leap_seconds}, #1,
  #       					start_at          => $self->{time}->{DateTime}->{Epoch}->{start_at}, #0,
  #       					local_epoch       => $self->{time}->{DateTime}->{Epoch}->{local_epoch}, #undef,
  #       				       );

  # my $ts = $tmp->parse_datetime( $time_in );
  my $ts = $self->mac_os_epoch( $time_in );

  my $time_out = Mktime(
			$ts->year,
			$ts->month,
			$ts->day,
			$ts->hour,
			$ts->minute,
			$ts->second
		       );

  return $time_out;

}
################################################################################
sub time_string_to_time_number {

  my $time_in = shift;

  my @tmp = split(/\s+/,$time_in);

  my $yr = $tmp[1];
  my $mo = $tmp[2];
  my $dy = $tmp[3];

  my ($hr,$mn,$sc) = 0;
  if ($#tmp>=4) { $hr = $tmp[4]; }
  if ($#tmp>=5) { $mn = $tmp[5]; }
  if ($#tmp>=6) { $sc = $tmp[6]; }

  my $time_out = '';

  if ($yr < 1990 ) { # seasonde's data cannot be before this date as SeaSonde's did not exist as a commerical product before this year

      
      return $time_out;

  } else {
    
    return $time_out = Mktime($yr,$mo,$dy,$hr,$mn,$sc);

  }
}
################################################################################
sub invalid_timestamp {

  my $self = shift;
  my $ts   = shift;

  if ( $ts eq '' ) {

    print "\nINVALID DATE ... RETURNING EMPTY SCALAR\n" if ($self->{misc}->{verbose}==1);
    return 1;

  } else {

    return 0;

  }

}
################################################################################
sub file_parts_from_ascii_table_type_and_config_file {

  my $self             = shift;
  my $table_type       = shift;
  my $pattern_type     = shift;
  my @tmp_table        = split(/\s+/,$table_type);
  my $test_table       = $tmp_table[1];
  my $test_field       = $tmp_table[2];

  # load in station configuration file
  my $config_file = $ENV{"HOME"}.'/acorn_perl_'.$self->{codenames}->{sos}.'.yml';
  my $sos_cfg     = LoadFile $config_file;

  # radials
  if ( $test_table =~ /$self->{codar}->{table_types}->{radial}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{radial}->{descriptor}*/i) { #/lluv/

    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{radial}; #'.ruv';

    # merged 
    if ( $test_field =~ /$self->{codar}->{table_types}->{radial}->{merged}\d/i ) { #rdl

      # delta time
      $self->{time}->{dt} = $sos_cfg->{header}->{radial}->{time}->{output_interval};

      # measured
      if ( $pattern_type =~ /$self->{codar}->{pattern_types}->{calibrated}/i ) { $self->{codar}->{fileops}->{type} = $self->{codar}->{prefixes}->{radial}->{merged}->{measured}; # measured ... 'rdlm'

      # ideal
      } else { $self->{codar}->{fileops}->{type} = $self->{codar}->{prefixes}->{radial}->{merged}->{ideal}; } #'rdli'
      
    # metric
    } elsif ( $test_field =~ /$self->{codar}->{table_types}->{radial}->{metric}\d/i ) { #rdm
      
      # delta time
      $self->{time}->{dt} = $sos_cfg->{cspro}->{time}->{averaging_period};

      # measured
      if ( $pattern_type =~ /$self->{codar}->{pattern_types}->{calibrated}/i ) { $self->{codar}->{fileops}->{type} = $self->{codar}->{prefixes}->{radial}->{metric}->{measured}; # measured ... 'rdlw'
      
      # ideal
      } else { $self->{codar}->{fileops}->{type} = $self->{codar}->{prefixes}->{radial}->{metric}->{ideal}; } #'rdlx'
    }

  # radial diagnostic
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{diagnostics}->{radial}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{diagnostics}->{radial}->{descriptor}*/i ) { #rads ... rad

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{diagnostics}; #'stat'; 
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{diagnostics}->{radial}; #'.rdt';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{diagnostics}->{time}->{output_interval};

  # hardware diagnostic
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{diagnostics}->{hardware}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{diagnostics}->{hardware}->{descriptor}*/i ) { #rcvr ... rcv

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{diagnostics}; #'stat';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{diagnostics}->{hardware}; #'.hdt';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{diagnostics}->{time}->{output_interval};

  # spectra diagnostic 
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{diagnostics}->{spectra}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{diagnostics}->{spectra}->{descriptor}*/i ) { #xspc ... spr

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{diagnostics}; #'stat';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{diagnostics}->{spectra}; #'.xdt';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{diagnostics}->{time}->{output_interval};

  # spectra point diagnostic
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{diagnostics}->{range}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{diagnostics}->{range}->{descriptor}*/i ) { #pcss ... rsp

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{diagnostics}; #'stat';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{diagnostics}->{range}; #'.sdt';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{diagnostics}->{time}->{output_interval};

  # vector creation diagnostic
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{diagnostics}->{vector}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{diagnostics}->{vector}->{descriptor}*/i ) { #pcss ... rsp

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{diagnostics}; #'stat';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{diagnostics}->{vector}; #'.ddt';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{diagnostics}->{time}->{output_interval};

  # waves
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{waves}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{waves}->{descriptor}/i ) { #wavl ... wvm
  
    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{waves}; #'wvlm';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{waves}; #'.wls';
    $self->{time}->{dt}                 = $sos_cfg->{extra}->{wave}->{time}->{output_interval};

  # vectors
  } elsif ( $test_table =~ /$self->{codar}->{table_types}->{vectors}->{table}/i and $test_field =~ /$self->{codar}->{table_types}->{vectors}->{descriptor}/i ) { #wavl ... wvm

    $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{vectors}; #'wvlm';
    $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{vectors}; #'.wls';
    $self->{time}->{dt}                 = $sos_cfg->{header}->{vector}->{time}->{output_interval};

  }

  return $self;

}
################################################################################
sub construct_archive_directory {

  my $self = shift;

  # put time in a more friendly format
  my ($yr,$mo,$dy,$hr,$mn,$sc,$do,$dw,$dt) = Date::Calc::Localtime( $self->{codar}->{fileops}->{file_time_stamp} );

  # ARCHIVE DIRECTORY
  # ARCHIVE BASE , STATION NAME , FILE TYPE , FILE YEAR , FILE MONTH , FILE DAY
  if ( $self->{codar}->{fileops}->{directory_structure} =~ /stymd/i ) { 

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s/%s/%04d/%02d/%02d" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) ,
							      uc($self->{codar}->{fileops}->{type}) ,
							      $yr ,
							      $mo ,
							      $dy );

  # ARCHIVE BASE , STATION NAME , FILE YEAR , FILE MONTH, FILE DAY
  } elsif ( $self->{codar}->{fileops}->{directory_structure} =~ /symd/i ) { 

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s/%04d/%02d/%02d" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) ,
							      $yr ,
							      $mo ,
							      $dy );

  # ARCHIVE BASE , STATION NAME , FILE TYPE , FILE YEAR , FILE MONTH
  } elsif ( $self->{codar}->{fileops}->{directory_structure} =~ /stym/i ) { 

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s/%s/%04d/%02d/%02d" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) ,
							      uc($self->{codar}->{fileops}->{type}) ,
							      $yr ,
							      $mo);

  # ARCHIVE BASE , STATION NAME , FILE TYPE , FILE YEAR
  } elsif ( $self->{codar}->{fileops}->{directory_structure} =~ /sty/i ) {

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s/%s/%04d" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) ,
							      uc($self->{codar}->{fileops}->{type}) ,
							      $yr);

  # ARCHIVE BASE , STATION NAME , FILE TYPE
  } elsif ( $self->{codar}->{fileops}->{directory_structure} =~ /st/i ) {

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s/%s" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) ,
							      uc($self->{codar}->{fileops}->{type}) );

  # ARCHIVE BASE , STATION NAME
  } elsif ( $self->{codar}->{fileops}->{directory_structure} =~ /s/i ) {

    $self->{codar}->{directories}->{archive}  = sprintf( "%s/%s" ,
							      $self->{codar}->{directories}->{base_archive} ,
							      uc($self->{codenames}->{sos}) );

  # ARCHIVE BASE
  } elsif ( $self->{codar}->{fileops}->{directory_structure} == "" ) {

    $self->{codar}->{directories}->{archive}  = sprintf( "%s" , $self->{codar}->{directories}->{base_archive} );

  }

  return $self;

}
################################################################################
sub construct_full_filename {

  my $self        = shift;
  my $test_suffix = $self->{codar}->{fileops}->{suffix};
  my $regex1      = qr/$self->{codar}->{suffixes}->{spectra}/i;
  my $regex2      = qr/$self->{codar}->{suffixes}->{time_series}|$self->{codar}->{suffixes}->{range_series}/i;
  my $regex3      = qr/$self->{codar}->{suffixes}->{radial}|$self->{codar}->{suffixes}->{waves}|$self->{codar}->{suffixes}->{vectors}/i;
  my $regex4      = qr/$self->{codar}->{suffixes}->{diagnostics}->{radial}|$self->{codar}->{suffixes}->{diagnostics}->{hardware}|$self->{codar}->{suffixes}->{diagnostics}->{spectra}|$self->{codar}->{suffixes}->{diagnostics}->{range}|$self->{codar}->{suffixes}->{diagnostics}->{vector}/i;
  
  # put time in a more friendly format
  my ($yr,$mo,$dy,$hr,$mn,$sc,$do,$dw,$dt) = Date::Calc::Localtime( $self->{codar}->{fileops}->{file_time_stamp} );

  # spectra
  if ( $test_suffix =~ $regex1 ) { #cs

    # years greater than 2000
    if ( $yr >= 2000 ) { $yr = ($yr)-2000;
    # 1900's
    } elsif ( $yr >= 1990 and $yr < 2000 ) { $yr = ($yr)-1900; }

    $self->{codar}->{fileops}->{full_filename} = sprintf( "%s/%s_%s_%02d_%02d_%02d_%02d%02d.%s" ,
							       $self->{codar}->{directories}->{archive} ,
							       uc($self->{codar}->{fileops}->{type}) ,
							       uc($self->{codenames}->{sos}) ,
							       $yr ,
							       $mo ,
							       $dy ,
							       $hr ,
							       $mn ,
							       $test_suffix);

  # range and time series
  } elsif ( $test_suffix =~ $regex2 ) { #rs|ts


    $self->{codar}->{fileops}->{full_filename} = sprintf( "%s/%s_%s_%04d_%02d_%02d_%02d%02d%02d.%s" ,
							       $self->{codar}->{directories}->{archive} ,
							       uc($self->{codar}->{fileops}->{type}) ,
							       uc($self->{codenames}->{sos}) ,
							       $yr ,
							       $mo ,
							       $dy ,
							       $hr ,
							       $mn ,
							       $sc ,
							       $test_suffix);

  # radial and waves
  } elsif ( $test_suffix =~ $regex3 ) { #tuv|wls|tuv


    $self->{codar}->{fileops}->{full_filename} = sprintf( "%s/%s_%s_%04d_%02d_%02d_%02d%02d.%s" ,
							       $self->{codar}->{directories}->{archive} ,
							       uc($self->{codar}->{fileops}->{type}) ,
							       uc($self->{codenames}->{sos}) ,
							       $yr ,
							       $mo ,
							       $dy ,
							       $hr ,
							       $mn ,
							       $test_suffix);

  # diagnostics
  # sdt diagnostics have extra fields in the original filename
  # I cannot find the value in keeping this informaiton so essentially renaming the files
  # without these four 'extra' fields
  } elsif ( $test_suffix =~ $regex4 ) { #rdt|hdt|xdt|sdt

    $self->{codar}->{fileops}->{full_filename} = sprintf( "%s/%s_%s_%04d_%02d_%02d.%s" ,
							       $self->{codar}->{directories}->{archive} ,
							       uc($self->{codar}->{fileops}->{type}) ,
							       uc($self->{codenames}->{sos}) ,
							       $yr ,
							       $mo ,
							       $dy ,
							       $test_suffix);

  }

  return $self;

}
################################################################################
sub archive_files_from_found_files {

  my $self = shift;

  # PULL OUT THE LIST OF FOUND FILES
  my @found_files = @{$self->{codar}->{filepops}->{found_files}};

  # LOOP OVER EACH FOUND FILE IN ARRAY $self->{codar}->{filepops}->{found_files}
  foreach my $found_file (@found_files) {

    # only archive files that are in the archive list
    my ($Fty,$Fsi,$Fyr,$Fmo,$Fmd,$Fhr,$Fmn,$Fsc) = $self->parse_filename( $found_file );
    if ( $Fty ~~ $self->{codar}->{fileops}->{archive_types} ) {

	# skip directories (partial matches)
	if (-d $found_file) { next; }

	# skip empty or missing files
	if ( (-z $found_file) or !(-e $found_file) ) {

	    print "\nEMPTY: $found_file ... SKIPPING\n" if ($self->{misc}->{verbose}==1);
	    $self->unlink_archive_or_found_file( $found_file );
	    next;

	}

	print "\nWORKING ON FOUND FILE: $found_file\n" if ($self->{misc}->{verbose}==1);

	$self->binary_archive($found_file) if (binary_check($found_file));

	$self->ascii_archive($found_file) if (ascii_check($found_file));

    } else {

	print "SKIPPING $found_file :: not in archive-type list\n" if ($self->{misc}->{verbose}==1);
	$self->unlink_archive_or_found_file( $found_file );
	
    }
  }
}
################################################################################
sub binary_check {

  my $test_file = shift;

  # Each binary header defaults to file_succes being empty so if one of them is a success then this will work
  my $cos_bin = HFR::SeaSonde::Binary->new_binary_file( full_filename => $test_file );
  $cos_bin->HFR::SeaSonde::Binary::get_time_series_header;
  $cos_bin->HFR::SeaSonde::Binary::get_range_series_header;
  $cos_bin->HFR::SeaSonde::Binary::get_cross_spectra_header;
  if ( $cos_bin->{file_success} == 1 ) {

    return 1;

  } else {

    return 0;

  }

}
################################################################################
sub binary_archive {

  my $self               = shift;
  my $found_file         = shift;
  my $table_time_series  = qr/$self->{codar}->{table_types}->{time_series}->{table}/i;
  my $table_range_series = qr/$self->{codar}->{table_types}->{range_series}->{table}/i;

  # Each binary header defaults to file_succes being empty so if one of them is a success then this will work
  my $cos_bin = HFR::SeaSonde::Binary->new_binary_file( full_filename => $found_file );
  $cos_bin->HFR::SeaSonde::Binary::get_time_series_header;
  $cos_bin->HFR::SeaSonde::Binary::get_range_series_header;
  $cos_bin->HFR::SeaSonde::Binary::get_cross_spectra_header;

  if ( $cos_bin->{file_success} == 1 ) {

    # time series
    $cos_bin->get_time_series_header;
    if ( $cos_bin->{file_test} =~ $table_time_series ) { #aqvl

      $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{time_series}; #'lvl';
      $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{time_series}; #'.ts';

    }

    # range series
    $cos_bin->get_range_series_header;
    if ( $cos_bin->{file_test} =~ $table_range_series ) { #aqft

      $self->{codar}->{fileops}->{type}   = $self->{codar}->{prefixes}->{range_series}; #'rng';
      $self->{codar}->{fileops}->{suffix} = $self->{codar}->{suffixes}->{range_series}; #'.rs';

    }

    # BAD spectra
    if ( !(looks_like_number($cos_bin->{cs_kind})) ) {

      print "\nFILE ERROR : something drastically wrong with binary file as 'cs_kind' is not a number ... skipping\n" if ($self->{misc}->{verbose}==1);
      $self->unlink_archive_or_found_file( $found_file );
      return $self;

    }
      
    # GOOD spectra
    if ( $cos_bin->{cs_kind} < $self->{codar}->{table_types}->{spectra}->{cs_kind} ) { #32

      $cos_bin->get_cross_spectra_header;
      print "CROSS SPECTRA\n" if ($self->{misc}->{verbose}==1);
      $self->{codar}->{fileops}->{suffix} = sprintf( "cs%d" , $cos_bin->{file_version} );

      # It should be noted that the next step of determining what 'type' of spectra file found file is is rather heavy-handed to say the least
      # At some point time should be spent to come up with a more robust way of determing which type of spectra file

      # csa
      if ( $cos_bin->{coverage_minutes} > 30 ) {

	print "cross spectra coverage minutes are greater than 30 -> assume ``average'' cross spectra (CSA)\n" if ($self->{misc}->{verbose}==1);
	$self->{codar}->{fileops}->{type} = 'csa';
	
	# css
      } elsif ( $cos_bin->{coverage_minutes} <=30 or $cos_bin->{coverage_minutes} > 10 ) {

	print "cross spectra coverage minutes are between 10 and 30 minutes -> assume cross spectra (CSS)\n" if ($self->{misc}->{verbose}==1);
	$self->{codar}->{fileops}->{type} = 'css';

	# csq
      } elsif ( $cos_bin->{coverage_minutes} <= 10 ) {

	print "cross spectra coverage minutes are between 10 and 30 minutes -> assumed ``UNaveraged'' cross spectra (CSQ)\n" if ($self->{misc}->{verbose}==1);
	$self->{codar}->{fileops}->{type} = 'csq';

      }
    }

    # if the above set parameters are empty then something is wrong and we need to skip the found file
    if ( $cos_bin->{station_name} eq '' or $cos_bin->{ts_1904} eq '' ) {

      print "\nFILE ERROR : found file is not healthy, does not have a station name or possibly a time stamp ... skipping \n" if ($self->{misc}->{verbose}==1);
      $self->unlink_archive_or_found_file( $found_file );
      return $self;

      # if the above file has a timestamp then attempt to construct a more easily comparable time
    } else {

      $self->{codar}->{fileops}->{file_time_stamp} = $self->time_seconds_from_1904_to_time_number( $cos_bin->{ts_1904} );
      $self->{codenames}->{sos}                    = $cos_bin->{station_name};
      $self->construct_archive_directory;
      $self->construct_full_filename;
      push @{$self->{codar}->{fileops}->{full_file_list}}, $self->{codar}->{fileops}->{full_filename};
      $self->file_compare_copy( $found_file ); 
      
    }
  }
  
  return $self;

}
################################################################################
sub ascii_check {

  my $test_file = shift;

  # Now will see if we are dealing with one of the ascii types of data
  my $cos_txt = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $test_file );
  $cos_txt->get_ascii_header;
  if ( $cos_txt->{file_success}==1 ) {

    return 1;

  } else {

    return 0;

  }
}
################################################################################
sub ascii_archive {

  my $self       = shift;
  my $found_file = shift;

  # Now will see if we are dealing with one of the ascii types of data
  print "\tchecking if file is asci ... " if ($self->{misc}->{verbose}==1);
  my $cos_txt = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $found_file );
  $cos_txt->get_ascii_header;
  if ( $cos_txt->{file_success}==1 ) {

    # again if header fields have come back empty then we must assume something is wrong with that file and skip it
    if ( ($cos_txt->{station_name} eq ' ') or ($cos_txt->{time_stamp} eq ' ') or ($cos_txt->{table_type} eq ' ') ) {

      print "\nFILE ERROR : found file is not healthy, does not have a station name or a time stamp or a table type ... skipping \n" if ($self->{misc}->{verbose}==1);
      $self->unlink_archive_or_found_file( $found_file );
      return $self;

      # if things are OK then construct the time stamp and return other useful information from the header
    } else {

      $self->{codar}->{fileops}->{file_time_stamp} = time_string_to_time_number( $cos_txt->{time_stamp} );
      return $self if ($self->invalid_timestamp( $self->{codar}->{fileops}->{file_time_stamp} ));
      my @tmp = split( /\s+/ , $cos_txt->{station_name} );
      $self->{codenames}->{sos} = $tmp[1];
      $self->file_parts_from_ascii_table_type_and_config_file( $cos_txt->{table_type} , $cos_txt->{pattern_type} );
      $self->construct_archive_directory;
      $self->construct_full_filename;
      push @{$self->{codar}->{fileops}->{full_file_list}}, $self->{codar}->{fileops}->{full_filename};
      $self->file_compare_copy( $found_file ); 
      
    }
  }

  return $self;

}
################################################################################
sub file_compare_copy {

  my $self       = shift;
  my $found_file = shift;
  my $archive_file  = $self->{codar}->{fileops}->{full_filename};
  my $regex1 = qr/^$self->{codar}->{prefixes}->{radials}|$self->{codar}->{prefixes}->{waves}|$self->{codar}->{prefixes}->{diagnostics}|$self->{codar}->{prefixes}->{vectors}/i;

  # check archive files existence
  # if it does not exist then this is a straight forward result ... copy/move found file to $archive_file
  if ( !(-f $archive_file) ) {

    print "Found file does *NOT* exist in $self->{codar}->{directories}->{archive}\n" if ($self->{misc}->{verbose}==1);
    $self->FILE_COPY( $found_file );

  # if it does exist then compare files
  } else {

    print "Found file exists in $self->{codar}->{directories}->{archive} , comparing files ...\n" if ($self->{misc}->{verbose}==1);

    # when files are the same don't worry about copying
    if ( compare( $found_file , $archive_file ) == 0 ) { 

      print "Files *ARE* equivalent, will not copy\n" if ($self->{misc}->{verbose}==1);
      $self->unlink_archive_or_found_file( $found_file );

    # when files are different then began checking differences
    } else {

      print "Files are *NOT* equivalent, more comparisons ...\n" if ($self->{misc}->{verbose}==1);

      # conditions and operatiosn on binary data
      if ( !($self->{codar}->{fileops}->{type} =~ $regex1) ) { #rdl|wvlm|stat|tuv

	$self->binary_file_comparisons( $found_file , $archive_file );

      # if it's an ascii type data then let's get some information on it
      } else {

	$self->ascii_file_comparisons( $found_file , $archive_file );

      }
    } 
  }
}
################################################################################
sub ascii_file_comparisons {

  my $self         = shift;
  my $found_file   = shift;
  my $archive_file = shift;

  # get info on archive file
  my $arch = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $archive_file );
  $arch->get_ascii_header;
  if ( $arch->{file_success}==1 ) {
	
    my @tmp = split( /\s+/ , $arch->{station_name} );
    my $arch_station_name = $tmp[1];
    my $arch_time_stamp   = $arch->{time_stamp};
    my $arch_table_type   = $arch->{table_type};

    # again if header fields have come back empty then we must assume something is wrong with that file and skip it
    if ( ($arch_station_name eq ' ') or ($arch_time_stamp eq ' ') or ($arch_table_type eq ' ') ) {

      print "ARCHIVE file is not healthy, does not have a station name or a time stamp or a table type\n" if ($self->{misc}->{verbose}==1);
      $self->{unlink_archive_file} = 1;
      $self->unlink_archive_or_found_file( $archive_file );
      $self->{unlink_archive_file} = 0;
      $self->FILE_COPY( $found_file );	  

    # if things are OK then compare processed time stamps
    } else {

      # make sure the archive file is who it says it is, by checking filename time with header time
      my ($Fty,$Fsi,$Fyr,$Fmo,$Fmd,$Fhr,$Fmn,$Fsc) = $self->parse_filename( $archive_file );
      my $tmp                                      = sprintf(' %04d %02d %02d  %02d %02d %02d',$Fyr,$Fmo,$Fmd,$Fhr,$Fmn,$Fsc); #space at start of string is necessary
      my $arch_ts_fn                               = time_string_to_time_number( $tmp );
      return $self if ($self->invalid_timestamp( $arch_ts_fn ));
      my $arch_hdr                                 = $arch->HFR::SeaSonde::ASCII::get_ascii_header;
      my $arch_ts                                  = time_string_to_time_number( $arch_hdr->{processed_time_stamp} );
      return $self if ($self->invalid_timestamp( $arch_ts ));
      unless ($arch_ts == $arch_ts_fn) { 

	print "Archive file is NOT OK\n" if ($self->{misc}->{verbose}==1);
	print "Filename time and header time are not equivalent\n" if ($self->{misc}->{verbose}==1);
	print "Therefore overwriting Archive file with Found file\n" if ($self->{misc}->{verbose}==1);
	$self->{unlink_archive_file} = 1;
	$self->unlink_archive_or_found_file( $archive_file );
	$self->{unlink_archive_file} = 0;
	$self->FILE_COPY( $found_file );	 
 
      } else {

	my $found     = HFR::SeaSonde::ASCII->new_ascii_file( full_filename => $found_file );
	my $found_hdr = $found->HFR::SeaSonde::ASCII::get_ascii_header;
	my $found_ts  = time_string_to_time_number( $found_hdr->{processed_time_stamp} );
	return $self if ($self->invalid_timestamp( $found_ts ));

	# could / should add checking with software versions, of course the file_type condition will
	# then need to be modify accordingly
	if ( $arch_ts > $found_ts ) { 

	  print "Archive file processed time stamp is newer than found file\n" if ($self->{misc}->{verbose}==1);
	  print "therefore do not overwrite, skipping found file ...\n" if ($self->{misc}->{verbose}==1);

	# straightforward enough ...
	} elsif ( $arch_ts < $found_ts ) {

	  print "Archive file processed time stamp is older tnan found file\n" if ($self->{misc}->{verbose}==1);
	  print "Therefore *overwriting* archive file with found file\n" if ($self->{misc}->{verbose}==1);
	  $self->{unlink_archive_file} = 1;
	  $self->unlink_archive_or_found_file( $archive_file );
	  $self->{unlink_archive_file} = 0;
	  $self->FILE_COPY( $found_file );

	  # processed file time stamps are equivalent ... more comparisons
	} else {

	  print "Archive file and found file processed time stamps are equivalent\n" if ($self->{misc}->{verbose}==1);
	  print "More comparisons between the files needs to be done but these routines are not written yet\n" if ($self->{misc}->{verbose}==1);
	  print "Therefore at present leave both files where they are ... essentially SKIPPING found file\n" if ($self->{misc}->{verbose}==1);
	  # ADD MORE CHECKING HERE; WILL REQUIRE COMPARING DATA AND BITS; BIGGER JOB

	}
      }
    }

  # Archive file could not be loaded successfully there fore something must be wrong with it so overwrite it
  } else {

    print "ARCHIVE file is not healthy, cannot be loaded using HFR::SeaSonde::ASCII\n" if ($self->{misc}->{verbose}==1);
    $self->{unlink_archive_file} = 1;
    $self->unlink_archive_or_found_file( $archive_file );
    $self->{unlink_archive_file} = 0;
    $self->FILE_COPY( $found_file );

  }
}
################################################################################
sub binary_file_comparisons {

  my $self = shift;
  my $found_file = shift;
  my $archive_file = shift;

  # load in archived binary file and check to success
  # if successful then compare further else overwrite archive file with found file
  my $arch = HFR::SeaSonde::Binary->new_binary_file( full_filename => $archive_file );
  $arch->get_time_series_header;
  $arch->get_range_series_header;
  $arch->get_cross_spectra_header;
  if ( $arch->{file_success} == 1 ) {

    # again if header fields have come back empty then we must assume something is wrong with that file and skip it
    if ( ($arch->{station_name} eq ' ') or ($arch->{ts_1904} eq ' ') ) {

      print "Archive file does not contain a 'station name' or 'time stamp'\n" if ($self->{misc}->{verbose}==1);
      print "Therfore overwrite archive file with found file\n" if ($self->{misc}->{verbose}==1);
      $self->{unlink_archive_file} = 1;
      $self->unlink_archive_or_found_file( $archive_file );
      $self->{unlink_archive_file} = 0;
      $self->FILE_COPY( $found_file );

    } else {

      # if for some reason the two time stamps do no agree then trust the incoming one and overwrite the archive file
      # THIS IS A BIG ASSUMPTION!
      eval {

	$arch->{file_time_stamp} = $self->time_seconds_from_1904_to_time_number( $arch->{ts_1904} );

      } or do {

	print "Archive file does not have a valid time, overwriting\n" if ($self->{misc}->{verbose}==1);
	$self->{unlink_archive_file} = 1;
	$self->unlink_archive_or_found_file( $archive_file );
	$self->{unlink_archive_file} = 0;
	$self->FILE_COPY( $found_file );
	return;

      };
  
      if ( $self->{codar}->{fileops}->{file_time_stamp} ne $arch->{file_time_stamp} ) {

	print "Archive file does not contain a 'station name' or 'time stamp'\n" if ($self->{misc}->{verbose}==1);
	print "Therfore overwrite archive file with found file\n" if ($self->{misc}->{verbose}==1);
	$self->{unlink_archive_file} = 1;
	$self->unlink_archive_or_found_file( $archive_file );
	$self->{unlink_archive_file} = 0;
	$self->FILE_COPY( $found_file );

      } else {

	print "Binary comparisons complete\nFiles are different but have the same time stamp" if ($self->{misc}->{verbose}==1);

      }
    } 

  } else {

    print "Archive file is *not* in fact a binary file whilst found file is\n" if ($self->{misc}->{verbose}==1);
    print "Therfore overwrite archive file with found file\n" if ($self->{misc}->{verbose}==1);
    $self->{unlink_archive_file} = 1;
    $self->unlink_archive_or_found_file( $archive_file );
    $self->{unlink_archive_file} = 0;
    $self->FILE_COPY( $found_file );
	  
  }

}
################################################################################
sub FILE_COPY {

  my $self       = shift;
  my $found_file = shift;

  # MAKE ARCHIVE PATH IF IT DOESN'T ALREADY EXIST
  unless (-d $self->{codar}->{directories}->{archive} and $self->{misc}->{debug}==0 ) {

      make_path($self->{codar}->{directories}->{archive}, {
								verbose => $self->{misc}->{verbose},
								mode => 0755
							       }
	       );
    }

  # CHECK TO SEE IF FILE IS AN USER DEFINED ARCHIVE FILE TYPE
  if ( $self->{codar}->{fileops}->{type} ~~ $self->{codar}->{fileops}->{archive_types} ) {

    # MOVE FOUND FILE
    if ($self->{codar}->{fileops}->{move}==1) {

      print "MOVING from: $found_file\n" if  ($self->{misc}->{verbose}==1);
      print "MOVING to  : $self->{codar}->{fileops}->{full_filename}\n\n" if ($self->{misc}->{verbose}==1);
    
      if ($self->{misc}->{debug}==0) {

	move( $found_file , $self->{codar}->{fileops}->{full_filename} ) or print "MOVE FAILED: $!\n";

      }

      # COPY FOUND FILE
    } elsif ($self->{codar}->{fileops}->{move}==0) {

      print "COPYING from: $found_file\n" if  ($self->{misc}->{verbose}==1);
      print "COPYING to  : $self->{codar}->{fileops}->{full_filename}\n\n" if ($self->{misc}->{verbose}==1);

      if ($self->{misc}->{debug}==0) {

	copy( $found_file , $self->{codar}->{fileops}->{full_filename} ) or print "COPY FAILED: $!\n";

      }
    }

  } else {

    my $tmp_txt = sprintf("NO COPY: %s\nFile type not in user-defined 'archive_types':%s",$found_file,Dumper($self->{codar}->{fileops}->{archive_types}));
    print $tmp_txt if  ($self->{misc}->{verbose}==1);

  }

  # DELETE FOUND FILE
  $self->unlink_archive_or_found_file( $found_file );

}
################################################################################
sub unlink_archive_or_found_file {

  my $self        = shift;
  my $unlink_file = shift;

  if ( $self->{codar}->{fileops}->{unlink_found_file}==1 ) {

    print "!!! DELETING FOUND FILE: $unlink_file\n" if ($self->{misc}->{verbose}==1);
    unlink $unlink_file unless ($self->{misc}->{debug}==1);

  }

  if ( $self->{codar}->{fileops}->{unlink_archive_file}==1 ) {

    print "!!! DELETING ARCHIVE FILE: $unlink_file\n" if ($self->{misc}->{verbose}==1);
    unlink $unlink_file unless ($self->{misc}->{debug}==1);

  }

}
################################################################################

1;

__END__

=head1 NAME

HFR::SeaSonde::FileOps - for use with CODAR Ocean Sensors SeaSonde data.

=head1 VERSION

Version 1.23

=head1 SYNOPSIS

HFR::SeaSonde::FileOps is written to easily deal with large quantities of CODAR Ocean SeaSonde (COS) data ASCII and Binary files.  Whether it be organising these files for archiving or transferring from one location to another for extracting information, this module is intended to be the I<swiss army knife> for COS data.

Here's a quick example of one of the intended uses. Say you'd like to build a list of measured radial files from Nora Creina from 12 August 2012 to the present:

=head2 EXAMPLE

  my $seasonde = HFR::SeaSonde::FileOps->new_operation(
     	                                               sos                    => 'Nora',
	                                               start                  => '12 August 2012',
						       stop                   => '',
						       data_type_primary      => 'LLUV RDL9',
						       data_type_secondary    => 'measured',
						       base_archive_directory => $params->{acorn_server}->{base_incoming_directory},
						       directory_structure    => 'symd'
                                                       );

  $seasonde->construct_file_list;

Plenty of assumptions (default parameters) are made in the above example when calling C<< HFR::SeaSonde->new_operation >>; B<the backbone of HFR::SeaSonde::FileOps is the B<YAML configuration file>. See L<HFR::YAML>.>

=head1 REQUIREMENTS

The following is a list of required packages/modules:

=over 6

=item HFR::SeaSonde::ASCII

See L<HFR::SeaSonde::ASCII>

=item HFR::SeaSonde::Binary

See L<HFR::SeaSonde::Binary>

=item Data::Dumper

See L<Data::Dumper>

=item DateTime

See L<DateTime>

=item DateTime::Format::Epoch::MacOS

See L<DateTime::Format::Epoch::MacOS>

=item DateTime::Format::Strptime

See L<DateTime::Format::Strptime>

=item Date::Calc

See L<Date::Calc>

=item YAML::XS

See L<YAML::XS>

=item Scalar::Util

See L<Scalar::Util>

=back

=head1 METHODS

=head2 new_operation

Reads in YAML configuration file (see L<HFR::YAML>) and accepts the following inputs:

=over 12

=item C<sos>

Station OR Site.

=item C<start>

Start time; "2010-09-20 15:14"

=item C<stop>

Start time; "2010-09-21 15:14"

=item C<archive_types>

String of SeaSonde types that are to be archived

=item C<data_type_primary>

Refers to CTF Keyword 'TableType'

=item C<data_type_secondary>

Refers to CTF Keyword 'TableType'

=item C<search_directory>

Directory to search for SeaSonde files

=item C<base_archive_directory>

Where found files will be copied

=item C<directory_structure>

String the directs what sub-directories will be under the archive directory:
  's' : station
  't' : type of data
  'y' : year
  'm' : month
  'd' : day

These are combined together in whatever format -- i.e. 'stymd' would create archive_direcory/station/type/year/month/day

=item C<file_move>

This is a Boolean control to turn on moving instead of copying

=item C<unlink_found_file>

This is a Boolean control to delete (unlink) the found files

=item C<unlink_archive_file>

This is a Boolean control to delete (unlink) the archive file prior to moving the found file

=item C<owner>

String for the name of the user who owns the files

=item C<debug>

Boolean control to turn on debugging which doesn't perform any actions

=item C<verbose>

Boolean control to begin reporting information to STDOUT

=back

=head2 read_config_header

This will read in the COS radial configuration file: header.txt and return all the parameters in a hash.
This method does not require method 'NEW' to be called as an object.

EXAMPLE:
use HFR::SeaSonde::FileOps (read_config_header);
my %cos_header = read_config_header( '/codar/seasonde/configs/radialconfigs/header.txt' );

Hash Arrary Fields (see SeaSonde Configuration File Formats)
Station_Number              :
Station_Code                :
Station_Description         :
Receiver_Antenna_Latitude   :
Receiver_Antenna_Longitude  :
Loop1_Bearing               : degrees clockwise from true North



=head2 archive_files_from_found_files

this will essentially take the new operation method and work to effectively copy all the files found in a search directory to an archive directory

=head2 construct_file_list

Report a list of files

=head2 parse_filename

Pull apart the components of a file; NOT EXPORTED

=head2 find_files

Search for the files; NOT EXPORTED

=head2 time_seconds_from_1904_to_time_number

The number of seconds from 1904; NOT EXPORTED

=head2 time_string_to_time_number

A string that contains a date and time to a POSIX; NOT EXPORTED

=head2 invalid_timestamp

Test the validity of a time stamp; NOT EXPORTED

=head2 file_parts_from_ascii_table_type_and_config_file

Read the CTF table parts keyword and make parts of a filename; NOT EXPORTED

=head2 construct_archive_directory

Make the directory where the found files will be stored under; NOT EXPORTED

=head2 construct_full_filename

Take all the parts of a full path file name and put them together; NOT EXPORTED

=head2 binary_check

check to see if the found file is binary file type; NOT EXPORTED

=head2 binary_archive

archive a binary file; NOT EXPORTED

=head2 ascii_check

check to see if the found file is an ASCII file type; NOT EXPORTED

=head2 ascii_archive

archive an ascii file; NOT EXPORTED

=head2 file_compare_copy

begin the process of comparing files; NOT EXPORTED

=head2 ascii_file_comparison

ascii file comparisons; NOT EXPORTED

=head2 binary_file_comparison

ascii file comparisons; NOT EXPORTED

=head2 FILE_COPY

copy or move the file; NOT EXPORTED

=head2 unlink_archive_or_found_file

delete files; NOT EXPORTED

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Daniel Atwater, E<lt>danielpath2o@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Atwater

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.08 or,
at your option, any later version of Perl 5 you may have available.


=cut
