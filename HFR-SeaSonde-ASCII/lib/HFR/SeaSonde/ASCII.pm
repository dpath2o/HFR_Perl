package HFR::SeaSonde::ASCII;

use 5.012003;
use strict;
use PDL;
#use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HFR::SeaSonde::ASCII ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.01';

sub new_ascii_file {

  # ESTABLISH THE METHOD
  my($class, %args) = @_;
  my $self          = bless( {} , $class );

  # NAME AND ``GOOD FILE''
  my $full_filename      = exists $args{full_filename} ? $args{full_filename} : '';
  $self->{full_filename} = $full_filename;
  my $file_success        = exists $args{file_success} ? $args{file_success} : 0;
  $self->{file_success}   = $file_success;

  # COMMON TO MOST ASCII FILES
  my $CTF                          = exists $args{CTF} ? $args{CTF} : '';
  $self->{CTF}                     = $CTF;
  my $table_format                 = exists $args{table_format} ? $args{table_format} : '';
  $self->{table_format}            = $table_format;
  my $UUID                         = exists $args{UUID} ? $args{UUID} : '';
  $self->{UUID}                    = $UUID;
  my $manufacturer                 = exists $args{manufacturer} ? $args{manufacturer} : '';
  $self->{manufacturer}            = $manufacturer;
  my $station_name                 = exists $args{station_name} ? $args{station_name} : '';
  $self->{station_name}            = $station_name;
  my $time_stamp                   = exists $args{time_stamp} ? $args{time_stamp} : '';
  $self->{time_stamp}              = $time_stamp;
  my $time_zone                    = exists $args{time_zone} ? $args{time_zone} : '';
  $self->{time_zone}               = $time_zone;
  my $time_coverage                = exists $args{time_coverage} ? $args{time_coverage} : '';
  $self->{time_coverage}           = $time_coverage;
  my $origin                       = exists $args{origin} ? $args{origin} : '';
  $self->{origin}                  = $origin;
  my $range_start                  = exists $args{range_start} ? $args{range_start} : '';
  $self->{range_start}             = $range_start;
  my $range_end                    = exists $args{range_end} ? $args{range_end} : '';
  $self->{range_end}               = $range_end;
  my $range_resolution             = exists $args{range_resolution} ? $args{range_resolution} : '';
  $self->{range_resolution}        = $range_resolution;
  my $antenna_bearing              = exists $args{antenna_bearing} ? $args{antenna_bearing} : '';
  $self->{antenna_bearing}         = $antenna_bearing;
  my $center_frequency             = exists $args{center_frequency} ? $args{center_frequency} : '';
  $self->{center_frequency}        = $center_frequency;
  my $doppler_resolution           = exists $args{doppler_resolution} ? $args{doppler_resolution} : '';
  $self->{doppler_resolution}      = $doppler_resolution;
  my $velocity_limit               = exists $args{velocity_limit} ? $args{velocity_limit} : '';
  $self->{velocity_limit}          = $velocity_limit;
  my $sweep_rate                   = exists $args{sweep_rate} ? $args{sweep_rate} : '';
  $self->{sweep_rate}              = $sweep_rate;
  my $frequency_bandwidth          = exists $args{frequency_bandwidth} ? $args{frequency_bandwidth} : '';
  $self->{frequency_bandwidth}     = $frequency_bandwidth;
  my $table_type                   = exists $args{table_type} ? $args{table_type} : '';
  $self->{table_type}              = $table_type;
  my $columns                      = exists $args{columns} ? $args{columns} : '';
  $self->{columns}                 = $columns;
  my $column_types                 = exists $args{column_types} ? $args{column_types} : '';
  $self->{column_types}            = $column_types;
  my $table_rows                   = exists $args{table_rows} ? $args{table_rows} : '';
  $self->{table_rows}              = $table_rows;
  my $processed_time_stamp         = exists $args{processed_time_stamp} ? $args{processed_time_stamp} : '';
  $self->{processed_time_stamp}    = $processed_time_stamp;
  my $radial_diag_version          = exists $args{radial_diag_version} ? $args{radial_diag_version} : '';
  $self->{radial_diag_version}     = $radial_diag_version;
  my $spectra_diag_version         = exists $args{spectra_diag_version} ? $args{spectra_diag_version} : '';
  $self->{spectra_diag_version}    = $spectra_diag_version;
  my $point_extractor_version      = exists $args{point_extractor_version} ? $args{point_extractor_version} : '';
  $self->{point_extractor_version} = $point_extractor_version;
  my $analyzespectra_version       = exists $args{analyzespectra_version} ? $args{analyzespectra_version} : '';
  $self->{analyzespectra_version}  = $analyzespectra_version;


  # RADIALS
  my $LLUV_spec                           = exists $args{LLUV_spec} ? $args{LLUV_spec} : '';
  $self->{LLUV_spec}                      = $LLUV_spec;
  my $great_circle                        = exists $args{great_circle} ? $args{great_circle} : '';
  $self->{great_circle}                   = $great_circle;
  my $geod_version                       = exists $args{geiod_version} ? $args{geod_version} : '';
  $self->{geod_version}                  = $geod_version;
  my $trust_flag                          = exists $args{trust_flag} ? $args{trust_flag} : '';
  $self->{trust_flag}                     = $trust_flag;
  my $reference_bearing                   = exists $args{reference_bearing} ? $args{reference_bearing} : '';
  $self->{reference_bearing}              = $reference_bearing;
  my $angular_resolution                  = exists $args{angular_resolution} ? $args{angular_resolution} : '';
  $self->{angular_resolution}             = $angular_resolution;
  my $spatial_resolution                  = exists $args{spatial_resolution} ? $args{spatial_resolution} : '';
  $self->{spatial_resolution}             = $spatial_resolution;
  my $pattern_type                        = exists $args{pattern_type} ? $args{pattern_type} : '';
  $self->{pattern_type}                   = $pattern_type;
  my $pattern_date                        = exists $args{pattern_date} ? $args{pattern_date} : '';
  $self->{pattern_date}                   = $pattern_date;
  my $pattern_resolution                  = exists $args{pattern_resolution} ? $args{pattern_resolution} : '';
  $self->{pattern_resolution}             = $pattern_resolution;
  my $pattern_smoothing                   = exists $args{pattern_smoothing} ? $args{pattern_smoothing} : '';
  $self->{pattern_smoothing}              = $pattern_smoothing;
  my $pattern_UUID                        = exists $args{pattern_UUID} ? $args{pattern_UUID} : '';
  $self->{pattern_UUID}                   = $pattern_UUID;
  my $first_order_method                  = exists $args{first_order_method} ? $args{first_order_method} : '';
  $self->{first_order_method}             = $first_order_method;
  my $bragg_smoothing_points              = exists $args{bragg_smoothing_points} ? $args{bragg_smoothing_points} : '';
  $self->{bragg_smoothing_points}         = $bragg_smoothing_points;
  my $bragg_second_order                  = exists $args{bragg_second_order} ? $args{bragg_second_order} : '';
  $self->{bragg_second_order}             = $bragg_second_order;
  my $radial_peak_dropoff                 = exists $args{radial_peak_dropoff} ? $args{radial_peak_dropoff} : '';
  $self->{radial_peak_dropoff}            = $radial_peak_dropoff;
  my $radial_peak_null                    = exists $args{radial_peak_null} ? $args{radial_peak_null} : '';
  $self->{radial_peak_null}               = $radial_peak_null;
  my $radial_noise_threshold              = exists $args{radial_noise_threshold} ? $args{radial_noise_threshold} : '';
  $self->{radial_noise_threshold}         = $radial_noise_threshold;
  my $pattern_amplitude_corrections       = exists $args{pattern_amplitude_corrections} ? $args{pattern_amplitude_corrections} : '';
  $self->{pattern_amplitude_corrections}  = $pattern_amplitude_corrections;
  my $pattern_phase_corrections           = exists $args{pattern_phase_corrections} ? $args{pattern_phase_corrections} : '';
  $self->{pattern_phase_corrections}      = $pattern_phase_corrections;
  my $pattern_amplitude_calculations      = exists $args{pattern_amplitude_calculations} ? $args{pattern_amplitude_calculations} : '';
  $self->{pattern_amplitude_calculations} = $pattern_amplitude_calculations;
  my $pattern_phase_calculations          = exists $args{pattern_phase_calculations} ? $args{pattern_phase_calculations} : '';
  $self->{pattern_phase_calculations}     = $pattern_phase_calculations;
  my $radial_music_parameters             = exists $args{radial_music_parameters} ? $args{radial_music_parameters} : '';
  $self->{radial_music_parameters}        = $radial_music_parameters;
  my $merged_count                        = exists $args{merged_count} ? $args{merged_count} : '';
  $self->{merged_count}                   = $merged_count;
  my $radial_min_merge_points             = exists $args{radial_min_merge_points} ? $args{radial_min_merge_points} : '';
  $self->{radial_min_merge_points}        = $radial_min_merge_points;
  my $first_order_calculations            = exists $args{first_order_calculations} ? $args{first_order_calculations} : '';
  $self->{first_order_calculations}       = $first_order_calculations;
  my $radial_merge_method                 = exists $args{radial_merge_method} ? $args{radial_merge_method} : '';
  $self->{radial_merge_method}            = $radial_merge_method;
  my $pattern_method                      = exists $args{pattern_method} ? $args{pattern_method} : '';
  $self->{pattern_method}                 = $pattern_method;
  my $spectra_range_cells                 = exists $args{spectra_range_cells} ? $args{spectra_range_cells} : '';
  $self->{spectra_range_cells}            = $spectra_range_cells;
  my $spectra_doppler_cells               = exists $args{spectra_doppler_cells} ? $args{spectra_doppler_cells} : '';
  $self->{spectra_doppler_cells}          = $spectra_doppler_cells;
  my $radial_merger_version               = exists $args{radial_merger_version} ? $args{radial_merger_version} : '';
  $self->{radial_merger_version}          = $radial_merger_version;
  my $spectra2radial_version              = exists $args{spectra2radial_version} ? $args{spectra2radial_version} : '';
  $self->{spectra2radial_version}         = $spectra2radial_version;
  my $radial_slider_version               = exists $args{radial_slider_version} ? $args{radial_slider_version} : '';
  $self->{radial_slider_version}          = $radial_slider_version;
  my $radial_archiver_version             = exists $args{radial_archiver_version} ? $args{radial_archiver_version} : '';
  $self->{radial_archiver_version}        = $radial_archiver_version;

  # WAVES
  my $coastline_sector                = exists $args{coastline_sector} ? $args{coastline_sector} : '';
  $self->{coastline_sector}           = $coastline_sector;
  my $wave_bragg_noise_threshold      = exists $args{wave_bragg_noise_threshold} ? $args{wave_bragg_noise_threshold} : '';
  $self->{wave_bragg_noise_threshold} = $wave_bragg_noise_threshold;
  my $wave_bragg_peak_dropoff         = exists $args{wave_bragg_peak_dropoff} ? $args{wave_bragg_peak_dropoff} : '';
  $self->{wave_bragg_peak_dropoff}    = $wave_bragg_peak_dropoff;
  my $wave_bragg_peak_null            = exists $args{wave_bragg_peak_null} ? $args{wave_bragg_peak_null} : '';
  $self->{wave_bragg_peak_null}       = $wave_bragg_peak_null;
  my $maximum_wave_period             = exists $args{maximum_wave_period} ? $args{maximum_wave_period} : '';
  $self->{maximum_wave_period}        = $maximum_wave_period;
  my $wave_bearing_limits             = exists $args{wave_bearing_limits} ? $args{wave_bearing_limits} : '';
  $self->{wave_bearing_limits}        = $wave_bearing_limits;
  my $wave_min_doppler_points         = exists $args{wave_min_doppler_points} ? $args{wave_min_doppler_points} : '';
  $self->{wave_min_doppler_points}    = $wave_min_doppler_points;
  my $wave_use_inner_bragg            = exists $args{wave_use_inner_bragg} ? $args{wave_use_inner_bragg} : '';
  $self->{wave_use_inner_bragg}       = $wave_use_inner_bragg;
  my $wave_follow_wind                = exists $args{wave_follow_wind} ? $args{wave_follow_wind} : '';
  $self->{wave_follow_wind}           = $wave_follow_wind;
  my $wave_merge_method               = exists $args{wave_merge_method} ? $args{wave_merge_method} : '';
  $self->{wave_merge_method}          = $wave_merge_method;
  my $wave_model_version              = exists $args{wave_model_version} ? $args{wave_model_version} : '';
  $self->{wave_model_version}         = $wave_model_version;
  my $spectra2wave_version            = exists $args{spectra2wave_version} ? $args{spectra2wave_version} : '';
  $self->{spectra2wave_version}       = $spectra2wave_version;
  my $wave_slider_version             = exists $args{wave_slider_version} ? $args{wave_slider_version} : '';
  $self->{wave_slider_version}        = $wave_slider_version;
  my $wave_archiver_version           = exists $args{wave_archiver_version} ? $args{wave_archiver_version} : '';
  $self->{wave_archiver_version}      = $wave_archiver_version;

  # HDT
  my $receiver                = exists $args{receiver} ? $args{receiver} : '';
  $self->{receiver}           = $receiver;
  my $attenuation             = exists $args{attenuation} ? $args{attenuation} : '';
  $self->{attenuation}        = $attenuation;
  my $sample_rate             = exists $args{sample_rate} ? $args{sample_rate} : '';
  $self->{sample_rate}        = $sample_rate;
  my $chirp_state             = exists $args{chirp_state} ? $args{chirp_state} : '';
  $self->{chirp_state}        = $chirp_state;
  my $blanking_state          = exists $args{blanking_state} ? $args{blanking_state} : '';
  $self->{blanking_state}     = $blanking_state;
  my $transmit_state          = exists $args{transmit_state} ? $args{transmit_state} : '';
  $self->{transmit_state}     = $transmit_state;
  my $sweep_state             = exists $args{sweep_state} ? $args{sweep_state} : '';
  $self->{sweep_state}        = $sweep_state;
  my $sweep_direction         = exists $args{sweep_direction} ? $args{sweep_direction} : '';
  $self->{sweep_direction}    = $sweep_direction;
  my $frequency_band          = exists $args{frequency_band} ? $args{frequency_band} : '';
  $self->{frequency_bank}     = $frequency_band;
  my $frequency_phases        = exists $args{frequency_phases} ? $args{frequency_phases} : '';
  $self->{frequency_phases}   = $frequency_phases;
  my $transponder_offset      = exists $args{transponder_offset} ? $args{transponder_offset} : '';
  $self->{transponder_offset} = $transponder_offset;
  my $sweep_alignment         = exists $args{sweep_alignment} ? $args{sweep_alignment} : '';
  $self->{sweep_alignment}    = $sweep_alignment;
  my $pulse_shaping           = exists $args{pulse_shaping} ? $args{pulse_shaping} : '';
  $self->{pulse_shaping}      = $pulse_shaping;
  my $transmit_watch          = exists $args{transmit_watch} ? $args{transmit_watch} : '';
  $self->{transmit_watch}     = $transmit_watch;
  my $watchdog_timeout        = exists $args{watchdog_timeout} ? $args{watchdog_timeout} : '';
  $self->{watchdog_timeout}   = $watchdog_timeout;
  my $blanking_period         = exists $args{blanking_period} ? $args{blanking_period} : '';
  $self->{blanking_period}    = $blanking_period;
  my $blank_delay             = exists $args{blank_delay} ? $args{blank_delay} : '';
  $self->{blank_delay}        = $blank_delay;
  my $enhanced_blanking       = exists $args{enchanced_blanking} ? $args{enchanced_blanking} : '';
  $self->{enchanced_blanking} = $enhanced_blanking;

  # SDT
  my $range_cells                  = exists $args{range_cells} ? $args{range_cells} : '';
  $self->{range_cells}             = $range_cells;
  my $spectra_first_rangecell      = exists $args{spectra_first_rangecell} ? $args{spectra_first_rangecell} : '';
  $self->{spectra_first_rangecell} = $spectra_first_rangecell;
  my $doppler_cells                = exists $args{doppler_cells} ? $args{doppler_cells} : '';
  $self->{doppler_cells}           = $doppler_cells;
  my $doppler_start                = exists $args{doppler_start} ? $args{doppler_start} : '';
  $self->{doppler_start}           = $doppler_start;
  my $doppler_end                  = exists $args{doppler_end} ? $args{doppler_end} : '';
  $self->{doppler_end}             = $doppler_end;
  my $peak_method                  = exists $args{peak_method} ? $args{peak_method} : '';
  $self->{peak_method}             = $peak_method;

  # TUV
  my $geod_version                = exists $args{geod_version} ? $args{geod_version} : '';
  $self->{geod_version}           = $geod_version;
  my $grid_created_by             = exists $args{grid_created_by} ? $args{grid_created_by} : '';
  $self->{grid_created_by}        = $grid_created_by;
  my $grid_version                = exists $args{grid_version} ? $args{grid_version} : '';
  $self->{grid_version}           = $grid_version;
  my $grid_time_stamp             = exists $args{grid_time_stamp} ? $args{grid_time_stamp} : '';
  $self->{grid_time_stamp}        = $grid_time_stamp;
  my $grid_modified_time          = exists $args{grid_modified_time} ? $args{grid_modified_time} : '';
  $self->{grid_modified_time}     = $grid_modified_time;
  my $grid_axis_orientation       = exists $args{grid_axis_orientation} ? $args{grid_axis_orientation} : '';
  $self->{grid_axis_orientation}  = $grid_axis_orientation;
  my $grid_axis_type              = exists $args{grid_axis_type} ? $args{grid_axis_type} : '';
  $self->{grid_axis_type}         = $grid_axis_type;
  my $grid_spacing                = exists $args{grid_spacing} ? $args{grid_spacing} : '';
  $self->{grid_spacing}           = $grid_spacing;
  my $averaging_radius            = exists $args{averaging_radius} ? $args{averaging_radius} : '';
  $self->{averaging_radius}       = $averaging_radius;
  my $distance_angular_limit      = exists $args{distance_angular_limit} ? $args{distance_angular_limit} : '';
  $self->{distance_angular_limit} = $distance_angular_limit;
  my $current_velocity_limit      = exists $args{current_velocity_limit} ? $args{current_velocity_limit} : '';
  $self->{current_velocity_limit} = $current_velocity_limit;
  
  # DATA
  my $data      = exists $args{data} ? $args{data} : '';
  $self->{data} = $data;

  # RETURN
  return $self;

}

=head2 get_ascii_header



=cut

sub get_ascii_header {

  my $self = shift;
  my $tmp  = '';

  #PULL OUT ALL LINES
  open(TEXT_FILE,"<$self->{full_filename}") or die "FATAL ERROR: Cannot open file '$self->{full_filename}' becasue $!\n";
  my @lines = <TEXT_FILE>;
  close(TEXT_FILE);

  # GENERAL
  ($tmp)                           = (split(/:/,(grep(/^\%CTF/,@lines))[0]))[1];
  $self->{CTF}                     = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%FileType/,@lines))[0]))[1];
  $self->{table_format}            = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%UUID/,@lines))[0]))[1];
  $self->{UUID}                    = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%Manufacturer/,@lines))[0]))[1];
  $self->{manufacturer}            = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%Site/,@lines))[0]))[1];
  $self->{station_name}            = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TimeStamp/,@lines))[0]))[1];
  $self->{time_stamp}              = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TimeZone/,@lines))[0]))[1];
  $self->{time_zone}               = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TimeCoverage/,@lines))[0]))[1];
  $self->{time_coverage}           = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%Origin/,@lines))[0]))[1];
  $self->{origin}                  = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TableType/,@lines))[0]))[1];
  $self->{table_type}              = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TableColumns/,@lines))[0]))[1];
  $self->{columns}                 = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TableColumnTypes/,@lines))[0]))[1];
  $self->{column_types}            = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%TableRows/,@lines))[0]))[1];
  $self->{table_rows}              = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/\%ProcessedTimeStamp/,@lines))[0]))[1];
  $self->{processed_time_stamp}    = $tmp; undef($tmp);
  ($tmp)                           = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"RadialDiagnostic\"/,@lines))[0]))[2];
  $self->{radial_diag_version}     = $tmp; undef($tmp);
  ($tmp)                           = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"SpectraDiagnostic\"/,@lines))[0]))[2];
  $self->{spectra_diag_version}    = $tmp; undef($tmp);
  ($tmp)                           = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"SpectraPointExtractor\"/,@lines))[0]))[2];
  $self->{point_extractor_version} = $tmp; undef($tmp);
  ($tmp)                           = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"AnalyzeSpectra\"/,@lines))[0]))[2];
  $self->{analyzespectra_version}  = $tmp; undef($tmp);

  # SUCCESS IS MINIMAL!
  $self->{file_success} = 1 unless ($self->{CTF} eq '');

  # RADIAL
  ($tmp)                                  = (split(/:/,(grep(/^\%LLUVSpec/,@lines))[0]))[1];
  $self->{LLUV_spec}                      = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%GreatCircle/,@lines))[0]))[1];
  $self->{great_circle}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%GeodVersion/,@lines))[0]))[1];
  $self->{geod_version}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%LLUVTrustData/,@lines))[0]))[1];
  $self->{trust_flag}                     = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RangeStart/,@lines))[0]))[1];
  $self->{range_start}                    = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RangeEnd/,@lines))[0]))[1];
  $self->{range_end}                      = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RangeResolutionKMeters/,@lines))[0]))[1];
  $self->{range_resolution}               = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%AntennaBearing/,@lines))[0]))[1];
  $self->{antenna_bearing}                = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%ReferenceBearing/,@lines))[0]))[1];
  $self->{reference_bearing}              = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%AngularResolution/,@lines))[0]))[1];
  $self->{angular_resolution}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%SpatialResolution/,@lines))[0]))[1];
  $self->{spatial_resolution}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternType/,@lines))[0]))[1];
  $self->{pattern_type}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternDate/,@lines))[0]))[1];
  $self->{pattern_date}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternResolution/,@lines))[0]))[1];
  $self->{pattern_resolution}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternSmoothing/,@lines))[0]))[1];
  $self->{pattern_smoothing}              = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternUUID/,@lines))[0]))[1];
  $self->{pattern_UUID}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%TransmitCenterFreqMHz/,@lines))[0]))[1];
  $self->{center_frequency}               = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%DopplerResolutionHZPerBin/,@lines))[0]))[1];
  $self->{doppler_resolution}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%FirstOrderMethod/,@lines))[0]))[1];
  $self->{first_order_method}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%BraggSmoothingPoints/,@lines))[0]))[1];
  $self->{bragg_smoothing_points}         = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%CurrentVelocityLimit/,@lines))[0]))[1];
  $self->{velocity_limit}                 = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%BraggHasSecondOrder/,@lines))[0]))[1];
  $self->{bragg_second_order}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RadialBraggPeakDropOff/,@lines))[0]))[1];
  $self->{radial_peak_dropoff}            = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RadialBraggPeakNull/,@lines))[0]))[1];
  $self->{radial_peak_null}               = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RadialBraggNoiseThreshold/,@lines))[0]))[1];
  $self->{radial_noise_threshold}         = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternAmplitudeCorrections/,@lines))[0]))[1];
  $self->{pattern_amplitude_corrections}  = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternPhaseCorrections/,@lines))[0]))[1];
  $self->{pattern_phase_corrections}      = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternAmplitudeCalculations/,@lines))[0]))[1];
  $self->{pattern_amplitude_calculations} = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternPhaseCalculations/,@lines))[0]))[1];
  $self->{pattern_phase_calculations}     = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RaialMusicParameters/,@lines))[0]))[1];
  $self->{radial_music_parameters}        = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%MergedCount/,@lines))[0]))[1];
  $self->{merged_count}                   = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%RadialMinimumMergePoints/,@lines))[0]))[1];
  $self->{radial_min_merge_points}        = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%FirstOrderCalc/,@lines))[0]))[1];
  $self->{first_order_calculations}       = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%MergeMethod/,@lines))[0]))[1];
  $self->{radial_merge_method}            = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%PatternMethod/,@lines))[0]))[1];
  $self->{pattern_method}                 = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%TransmitSweepRateHz/,@lines))[0]))[1];
  $self->{transmit_sweep_rate}            = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%TransmitBandwidthKHz/,@lines))[0]))[1];
  $self->{transmit_bandwidth}             = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%SpectraRangeCells/,@lines))[0]))[1];
  $self->{spectra_range_cells}            = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/:/,(grep(/^\%SpectraDopplerCells/,@lines))[0]))[1];
  $self->{spectra_doppler_cells}          = $tmp; undef{$tmp};
  ($tmp)                                  = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"RadialMerger\"/,@lines))[0]))[2];
  $self->{radial_merger_version}          = $tmp; undef($tmp);
  ($tmp)                                  = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"SpectraToRadial\"/,@lines))[0]))[2];
  $self->{spectra2radial_version}         = $tmp; undef($tmp);
  ($tmp)                                  = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"RadialSlider\"/,@lines))[0]))[2];
  $self->{radial_slider_version}          = $tmp; undef($tmp);
  ($tmp)                                  = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"RadialArchiver\"/,@lines))[0]))[2];
  $self->{radial_archiver_version}        = $tmp; undef($tmp);

  #WAVE
  ($tmp)                              = (split(/:/,(grep(/^\%CoastlineSector/,@lines))[0]))[1];
  $self->{coastline_sector}           = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveBraggNoiseThreshold/,@lines))[0]))[1];
  $self->{wave_bragg_noise_threshold} = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveBraggPeakDropOff/,@lines))[0]))[1];
  $self->{wave_bragg_peak_dropoff}    = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveBraggPeakNull/,@lines))[0]))[1];
  $self->{wave_bragg_peak_null}       = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%MaximumWavePeriod/,@lines))[0]))[1];
  $self->{maximum_wave_period}        = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveBearingLimits/,@lines))[0]))[1];
  $self->{wave_bearing_limit}         = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveMinDopplerPoints/,@lines))[0]))[1];
  $self->{wave_min_doppler_points}    = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveUseInnerBragg/,@lines))[0]))[1];
  $self->{wave_use_inner_bragg}       = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WavesFollowTheWind/,@lines))[0]))[1];
  $self->{wave_follow_wind}           = $tmp; undef{$tmp};
  ($tmp)                              = (split(/:/,(grep(/^\%WaveMergeMethod/,@lines))[0]))[1];
  $self->{wave_merge_method}          = $tmp; undef{$tmp};
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"WaveModelForFive\"/,@lines))[0]))[2];
  $self->{wave_model_version}         = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"SpectraToWavesModel\"/,@lines))[0]))[2];
  $self->{spectra2wave_version}       = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"WaveModelSlider\"/,@lines))[0]))[2];
  $self->{wave_slider_version}        = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"WaveModelArchiver\"/,@lines))[0]))[2];
  $self->{wave_archiver_version}      = $tmp; undef($tmp);

  #HDT
  ($tmp)                      = (split(/:/,(grep(/^\%Receiver/,@lines))[0]))[1];
  $self->{receiver}           = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%Attenuation/,@lines))[0]))[1];
  $self->{attenuation}        = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%SampleRate/,@lines))[0]))[1];
  $self->{sample_rate}        = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%ChirpState/,@lines))[0]))[1];
  $self->{chirp_state}        = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%BlankingState/,@lines))[0]))[1];
  $self->{blanking_state}     = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%TransmitState/,@lines))[0]))[1];
  $self->{transmit_state}     = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%SweepState/,@lines))[0]))[1];
  $self->{sweep_state}        = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%SweepDirection/,@lines))[0]))[1];
  $self->{sweep_direction}    = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%FrequencyBand/,@lines))[0]))[1];
  $self->{frequency_band}     = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%FrequencyPhases/,@lines))[0]))[1];
  $self->{frequency_phases}   = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%TransponderOffset/,@lines))[0]))[1];
  $self->{transponder_offset} = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%SweepAlignment/,@lines))[0]))[1];
  $self->{sweep_alignment}    = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%PulseShaping/,@lines))[0]))[1];
  $self->{pulse_shaping}      = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%TransmitWatch/,@lines))[0]))[1];
  $self->{transmit_watch}     = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%WatchdogTimeout/,@lines))[0]))[1];
  $self->{watchdog_timeout}   = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%BlankingPeriod/,@lines))[0]))[1];
  $self->{blanking_period}    = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%BlankDelay/,@lines))[0]))[1];
  $self->{blank_delay}        = $tmp; undef{$tmp};
  ($tmp)                      = (split(/:/,(grep(/^\%EnhancedBlanking/,@lines))[0]))[1];
  $self->{enchanced_blanking} = $tmp; undef{$tmp};
 
  #SDT
  ($tmp)                           = (split(/:/,(grep(/^\%RangeCells/,@lines))[0]))[1];
  $self->{range_cells}             = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%SpectraFirstRangeCellKM/,@lines))[0]))[1];
  $self->{spectra_first_rangecell} = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%DopplerCells/,@lines))[0]))[1];
  $self->{doppler_cells}           = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%DopplerStart/,@lines))[0]))[1];
  $self->{doppler_start}           = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%DopplerEnd/,@lines))[0]))[1];
  $self->{doppler_end}             = $tmp; undef{$tmp};
  ($tmp)                           = (split(/:/,(grep(/^\%PeakMethod/,@lines))[0]))[1];
  $self->{peak_method}             = $tmp; undef{$tmp};

  # TUV
  ($tmp)                              = (split(/:/,(grep(/^\%LLUVTrustData/,@lines))[0]))[1];
  $self->{LLUV_trust_data}            = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GeodVersion/,@lines))[0]))[1];
  $self->{geod_version}               = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridCreatedBy/,@lines))[0]))[1];
  $self->{grid_created_by}            = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridVersion/,@lines))[0]))[1];
  $self->{grid_version}               = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridTimeStamp/,@lines))[0]))[1];
  $self->{grid_time_stamp}            = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridLastModified/,@lines))[0]))[1];
  $self->{grid_modified_time}         = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridAxisOrientation/,@lines))[0]))[1];
  $self->{grid_axis_orientation}      = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridAxisType/,@lines))[0]))[1];
  $self->{grid_axis_type}             = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%GridSpacing/,@lines))[0]))[1];
  $self->{grid_spacing}               = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%AveragingRadius/,@lines))[0]))[1];
  $self->{averaging_radius}           = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%DistanceAngularLimit/,@lines))[0]))[1];
  $self->{distance_angular_limit}     = $tmp; undef($tmp);
  ($tmp)                              = (split(/:/,(grep(/^\%CurrentVelocityLimit/,@lines))[0]))[1];
  $self->{current_velocity_limit}     = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"Combiner\"/,@lines))[0]))[2];
  $self->{combiner_version}           = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"CheckForCombine\"/,@lines))[0]))[2];
  $self->{check_for_combine_version}  = $tmp; undef($tmp);
  ($tmp)                              = (split(/\s/,(grep(/\%ProcessingTool\:\s+\"TotalArchiver\"/,@lines))[0]))[2];
  $self->{total_archiver_version}     = $tmp; undef($tmp);


  #RETURN
  return $self;

}

sub get_ascii_data {

  my $self = shift;

  $self->{data} = rcols($self->{full_filename}, { EXCLUDE => '/^\%/' }, []);

  # #GET ALL LINES
  # open(TEXT_FILE,"<$self->{full_filename}") or die "Cannot open $self->{full_filename}: $!\n";
  # my @lines = <TEXT_FILE>;
  # close(TEXT_FILE);

  # #DATA ARE LINES THAT DON'T BEGIN WITH '%'
  # $self->{data} = grep( !/^\%/ , @lines );

  return $self

}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

HFR::SeaSonde::ASCII - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HFR::SeaSonde::ASCII;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HFR::SeaSonde::ASCII, created by h2xs. It looks like the
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
