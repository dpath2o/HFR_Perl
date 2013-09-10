#!/usr/bin/perl
#
# css_batch_reprocess.pl
#
# for reprocessing of CODAR Ocean Sensors SeaSonde cross spectra files
#

use strict;
use GetOpt::Long;
use Pod::Usage;
use File::Copy;
use File::Copy::Recursive;
use File::Find;
use POSIX qw(strftime);
use Time::Local;

################################################################################
# INITIALIZE
my $source_directory  = "/Codar/Seasonde/Archives/Spectra";
my $target_directory  = "$ENV{HOME}/Desktop";
my $proc_file_prefix  = 'CSS_';
my $proc_file_suffix  = '.cs4';
my $configs_directory = '/Codar/Seasonde/Configs/RadialConfigs';
my $procToolsFolder   = '/Codar/Seasonde/Apps/RadialTools/SpectraProcessing';
my $startTime         = 0;
my $stopTime          = 0;

################################################################################
# GET INPUTS
my $help_msg = 0;
my $result = GetOptions (
                         "h|help|?"            => \$help_msg,
                         "source_directory=s"  => \$source_directory,
                         "target_directory=s"  => \$target_directory,
                         "proc_file_prefix=s"  => \$proc_file_prefix,
                         "proc_file_suffix=s"  => \$proc_file_suffix,
                         "configs_directory=s" => \$configs_directory,
                         "binary_directory=s"  => \$procToolsFolder,
                         "start_time=s"        => \$startTime,
                         "stop_time=s"         => \$stopTime
                         );

################################################################################
# CREATE TARGET DIRECTORY AND DESCRIBE THE PARAMETERS TO THE LOG
$target_directory = sprintf "%s/Reprocess_%s", $target_directory, strftime("%y%m%d_%H%M%S", localtime $^T);
unless (-e $target_directory) { my $out = `mkdir -p $target_directory`; }

my $logfile = "$target_directory/ReprocessLog.txt";	# Define Log File name
open(LOG, ">", $logfile) or die "$!\n"; 		# open/create log file

my @logtargets = (STDOUT,LOG); # Where do messages go? (default = stdout & log file)

foreach (@logtargets) {print { $_ } "\n";}
foreach (@logtargets) {print { $_ } "CSS Reprocessing Info:\n\n";}
foreach (@logtargets) {print { $_ } "Data Source Folder:\n\t$source_directory\n\n";}
foreach (@logtargets) {print { $_ } "Data Target Folder:\n\t$target_directory\n\n";}
foreach (@logtargets) {print { $_ } "Process only files Beginning with:\n\t$proc_file_prefix\n\n";}
if ($proc_file_suffix) {foreach (@logtargets) {print { $_ } "Process only files Ending with:\n\t$proc_file_suffix\n\n";}}
if ($start_time) {foreach (@logtargets) {print { $_ } "Process only files time stamped at or after:\n\t$start_time\n\n";}}
if ($stop_time) {foreach (@logtargets) {print { $_ } "Process only files time stamped at or before:\n\t$stop_time\n\n";}}
foreach (@logtargets) {print { $_ } "Use Radial Config Files from:\n\t$configs_directory\n\n";}
foreach (@logtargets) {print { $_ } "Use Spectra Processing Tools in:\n\t$procToolsFolder\n\n";}

########################################################################
#### #### #### ####  Read From Configuration Files   #### #### #### ####
########################################################################

dircopy($configs_directory,$target_directory);
#my $status = `cp -pR "$configs_directory" "$target_directory"`;

## Config File Names
my $CosOptionsFile = $configs_directory."/AnalysisOptions.txt";
my $CosHeaderFile = $configs_directory."/Header.txt";

#########################################################################

my ($doRads,$doWaves,$pattParam,$doingCSS,$doShortRads,$nDopplerInterp,$doMetricRads,$OffShore,$ApplySymmetry,$UseInnerWaves);
my $line = '';
my @params = '';

## Check if AnalysisOptions file exists and get parameters from it
if (-e $CosOptionsFile) {

	open (FID, "< $CosOptionsFile");

	$line = <FID>;		# Line 1: Process Radials (1/0)
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$doRads = $params[0];

	$line = <FID>;		# Line 2: Process Waves (1/0)
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$doWaves = $params[0];

	$line = <FID>;		# Line 3: File Archiving: Ignored. No longer in use.
	$line = <FID>;		# Line 4: Antenna Pattern: 0(Ideal),1(Measured),2(Both); 
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$pattParam = $params[0];

	$line = <FID>;		# Line 5: Spectra Header Override: 0(Use CS Info),1(Use Header Info)
	$line = <FID>;		# Line 6: CSA Processing: 0(CSA->'Rad_'),1(CSS only)
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$doingCSS = $params[0];

	$line = <FID>;		# Line 7: Wave Processing: OffShore 0(No),1(Yes); ApplySymetry 0(No),1(Yes); UseInnerWaves 0(No),1(Yes)
 	$line =~ s/^\s+//;
 	@params = split(/\s+/,$line);
 	$OffShore = $params[0];
 	$ApplySymmetry = $params[1];
 	$UseInnerWaves = $params[2];

	$line = <FID>;		# Line 8: Elliptical Processing: 0(Off),1(On)
	$line = <FID>;		# Line 9: Ionospheric Noise: 0(Ignore), 1(Remove Offending RangeCells)

	$line = <FID>;		# Line 10: ShortTime Rad/Ellipticals: 0(Off), 1(Output) 
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$doShortRads = $params[0];

	$line = <FID>;      # Line 11:
	$line = <FID>;      # Line 12:
	$line = <FID>;      # Line 13:
	$line = <FID>;      # Line 14:
	$line = <FID>;      # Line 15:
	$line = <FID>;      # Line 16:
	$line = <FID>;      # Line 17:
	$line = <FID>;      # Line 18:

	$line = <FID>;      # Line 19: DopplerInterpolation: 0(Off), 1(Double)
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$nDopplerInterp = $params[0];
	if ($nDopplerInterp == 1) { $nDopplerInterp = 2; }

	$line = <FID>;      # Line 20:
	$line = <FID>;      # Line 21: Enable Radial Metric Output: 0(Off), 1(Enable), 2(Metric without Normal radial output)
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	$doMetricRads = $params[0];
	$line = <FID>;      # Line 22:
	close(FID);

} else {

	foreach (@logtargets) {print { $_ } "Can't continue: AnalysisOptions.txt does not exist in $configs_directory\n";}
	exit;

}

## Check if Header file exists and get parameters from it

if (-e $CosHeaderFile) {
	open (FID, "< $CosHeaderFile");

	$line = <FID>;
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	my $siteCode = $params[1];

	for (my $i = 2; $i < 21; $i++) {
		@params = split(/\s+/,<FID>);
	}

	$line = <FID>;
	$line =~ s/^\s+//;
	@params = split(/\s+/,$line);
	my $timeCoverage = $params[0];
	my $timeOutput = $params[1];
	my $OffsetMin = $params[2];
	my $IgnoreSpan = $params[3];

	close(FID);

} else {

	foreach (@logtargets) {print { $_ } "Can't continue: Header.txt does not exist in $configs_directory\n";}
	exit;

}

########################################################################
#### #### #### ####  Define Other Files & SubFolders #### #### #### ####
########################################################################

my $outputLLUV = 1;	## -1=use pref, 0=classic, 1=LLUV,
my $logdatefmt = "%F %T %Z";

if ($pattParam == 0) {
	@pattsToUse = ('ideal');
	$CosRadSubFolder{ideal} = "IdealPattern";
	foreach (@logtargets) {print { $_ } "Processing radials using ideal pattern\n\n";}
} elsif ($pattParam == 1) {
	@pattsToUse = ('meas');
	$CosRadSubFolder{meas} = "MeasPattern";
	foreach (@logtargets) {print { $_ } "Processing radials using measured pattern\n\n";}
} elsif ($pattParam == 2) {
	@pattsToUse = ('ideal', 'meas');
	%CosRadSubFolder = (
							ideal => "IdealPattern",
							meas => "MeasPattern",
						);
	foreach (@logtargets) {print { $_ } "Processing radials using ideal & measured patterns\n\n";}
} else {
	# Insert error handling here
}
if ($doWaves) {
	foreach (@logtargets) {print { $_ } "Processing for wave data\n\n";}
}

## Define/Create Necessary output subfolders
$CosProcFolder = $target_directory."/Processing";
unless (-e $CosProcFolder) {$out = `mkdir -p $CosProcFolder`;}

if ($doRads) {
	$CosRadialFolder = $target_directory."/Radials";
	foreach (keys %CosRadSubFolder) {
		unless (-e $CosRadialFolder."/$CosRadSubFolder{$_}") {$out = `mkdir -p $CosRadialFolder/$CosRadSubFolder{$_}`;}
		}
	}

if ($doShortRads) {
	$CosShortRadialFolder = $target_directory."/RadialShorts";
	foreach (keys %CosRadSubFolder) {
		unless (-e $CosShortRadialFolder."/$CosRadSubFolder{$_}") {$out = `mkdir -p $CosShortRadialFolder/$CosRadSubFolder{$_}`;}
		}
	}

if ($doMetricRads) {
	$CosMetricRadialFolder = $target_directory."/RadialMetrics";
	foreach (keys %CosRadSubFolder) {
		unless (-e $CosMetricRadialFolder."/$CosRadSubFolder{$_}") {$out = `mkdir -p $CosMetricRadialFolder/$CosRadSubFolder{$_}`;}
		}
	}

if ($doWaves) {
	$CosWaveFolder = $target_directory."/Waves";
	unless (-e $CosWaveFolder) {$out = `mkdir -p $CosWaveFolder`;}
	}

$CosDiagFolder = $target_directory."/Diagnostics";
unless (-e $CosDiagFolder) {$out = `mkdir -p $CosDiagFolder`;}

$CosFirstOrderFolder = $target_directory."/FirstOrderLines";
unless (-e $CosFirstOrderFolder) {$out = `mkdir -p $CosFirstOrderFolder`;}

## Files/Folders in Processing folder
$CosProcRadFile = $CosProcFolder."/RadialData.txt";
$CosProcRadSaveFile = $CosProcFolder."/RadialDataSave.txt";
$CosProcRadListFile = $CosProcFolder."/RadialSlider.list";
$CosProcSpectraAver = $CosProcFolder."/SpectraSliders/CSA_AVER_00_00_00_0000";
unless (-e "$CosProcFolder/SpectraSliders") {$out = `mkdir -p "$CosProcFolder/SpectraSliders"`;}
$CosProcRadResult = $CosProcFolder."/RdlsXXXX_00_00_00_0000.rv";

## Some other definitions
$CosVerboseFile = $configs_directory."/AnalysisVerbocity.txt";
$nextFileOutput = $CosProcFolder.'/SpectraToProcess.txt';

## Files to delete before each CSS is processed ##
@filesToDelete = (	$CosProcRadFile,
					$CosProcFolder."/RadialInfo.txt",
					$CosProcFolder."/RadialData.txt",
					$CosProcFolder."/ALim.txt",
					$CosProcFolder."/NoiseFloorNew.txt",
					$CosProcFolder."/CsMark.txt",
					$CosProcFolder."/AmpNew.txt",
					$CosProcFolder."/PhaseNew.txt",
					$CosProcFolder."/RadialDiagInfo.txt",
					$CosProcFolder."/RadialProcessed.txt",
					$CosProcFolder."/RadialXYProcessed.txt",
					$CosProcRadResult
);

########################################################################
#### #### #### ####   Search for Files to Process    #### #### #### ####
########################################################################

## Create master list of all files matching criteria in folder tree
find \&wanted, $source_directory;

## Sub function filter for files that begin with CSS & end with .cs4
sub wanted {if ($_ =~ /^$proc_file_prefix/ and $_ =~ /$proc_file_suffix$/ and ! -d) {$flist{$_} = $File::Find::name;}}
@cssFound = sort keys %flist;

@cssToProcess = ();
foreach my $cssFile (@cssFound) {
	
	my $fSite = substr $cssFile, 4, 4;
	unless ($fSite eq $siteCode) {next;}

	my $fTimeString = substr $cssFile, 9, 13;
	my $fYear = substr $cssFile, 9, 2;
	my $fMon  = substr $cssFile, 12, 2;
	my $fDay  = substr $cssFile, 15, 2;
	my $fHour = substr $cssFile, 18, 2;
	my $fMin  = substr $cssFile, 20, 2;
	my $timeFile = timelocal(0,$fMin,$fHour,$fDay,$fMon-1,$fYear);

	if ($startTime and ($timeFile < $startTime)) {next;}
	if ($stopTime and ($timeFile > $stopTime)) {next;}
	push @cssToProcess, $cssFile;
}

foreach (@logtargets) {printf { $_ } "%d files found, %d files to process\n", $#cssFound+1, $#cssToProcess+1;}

########################################################################
#### #### #### ####      Begin Processing Loop       #### #### #### ####
########################################################################

$filesProcessed = 0;

if ($#cssToProcess >= 0) {

	foreach (@logtargets) {printf { $_ } "Processing beginning at %s\n", strftime($logdatefmt, localtime);}
	foreach my $csfile (sort @cssToProcess) {

 		my $fsite = substr $csfile, 4, 4;
		my $ftime = substr $csfile, 9, 13;
		
		$filesProcessed++;

		unlink @filesToDelete;

		# Write each filename into SpectraToProcess.txt
		open (OUT, "> $nextFileOutput");
		print OUT "$flist{$csfile}\n";
		close (OUT);
	
		if (-e $CosProcSpectraAver) {rename $CosProcSpectraAver, $CosProcSpectraAver.'.old';}
		
		foreach (@logtargets) {printf { $_ } "  %s - %s (%d of %d) %3.1f%%\n", strftime("%T", localtime), $csfile, $filesProcessed, $#cssToProcess+1, ($filesProcessed/($#cssToProcess+1))*100;}
		
		# SpectraSlider args: <nDiagnostic> <nKeepMins> <nCoverageMins> <nOutputMinutes> <bIgnoreSpan> <nOffsetMin> <sProcFolder> <sCSAFolder> <bMakeCSA>
		foreach (@logtargets) {printf { $_ } "\tCalling SpectraSlider...\n";}		
		my $execStr = "$procToolsFolder/SpectraSlider 0 $timeCoverage $timeOutput $timeOutput 1 0 \"$CosProcFolder\" \"\" 0";
		my $output = `$execStr`;


		######################################################################
		#### #### #### ####     Radial Processing	  #### #### #### #### #### 
		######################################################################

		if ($doRads or $doShortRads) {
		
			foreach $pattType (@pattsToUse) {
				if ($pattType eq 'ideal') {
					$suffix=".ideal";
					$procChar="i";
					$shortChar="x";
					$metChar="v";
					$oldChar="s";
					$csaChar="_";
					$patt=0;
					$radType=1;
				} elsif ($pattType eq 'meas') {
					$suffix=".meas";
					$procChar="m";
					$shortChar="y";
					$metChar="w";
					$oldChar="z";
					$csaChar="p";
					$patt=1;
					$radType=2;
				}
				
				$outSaveBase="Rdl".$procChar."XXXX_00_00_00_0000";
	
				## SpectraToRadial args: <bAppend> <bPattern> <sSuffix> <nDiag> <bWaveOnly> <sCfgFolder> <sProcFolder>
				foreach (@logtargets) {printf { $_ } "\tCalling SpectraToRadial...\n";}
				my $execStr = "$procToolsFolder/SpectraToRadial 0 $patt \"$suffix\" 0 0 \"$configs_directory/\" \"$CosProcFolder/\"";
				my $output = `$execStr`;
				$didCurrent=1;
				
				## RadialDiagnostic args: <nDiag> <nRadType> <sProcFolder> <sDiagFolder>
				foreach (@logtargets) {printf { $_ } "\tCalling RadialDiagnostic...\n";}
				$execStr = "$procToolsFolder/RadialDiagnostic 0 $radType \"$CosProcFolder/\" \"$CosDiagFolder/\" \"$configs_directory\"";
				$output = `$execStr`;
				
				if ($doMetricRads) {
				    	foreach (@logtargets) {printf { $_ } "\tMetric Radials: Calling RadialArchiver...\n";}
					## Usage: <nDiag> <cProcChar> <sOwner> <sRadFolder> <sProcFolder> <bLLUV> <bOpen> <sCfgFolder> <nPattern> <sDiagFolder> <bRadInfo> <bRadSource>
					my $execStr = "$procToolsFolder/RadialArchiver 0 \"$metChar\" \"RadD\" \"$CosMetricRadialFolder/$CosRadSubFolder{$pattType}/\" \"$CosProcFolder/\" $outputLLUV 0 \"$configs_directory\" $patt \"$CosDiagFolder/\" 1 1 $nDopplerInterp \"\"";
					my $output = `$execStr`;
				}
				
				if ($doShortRads) {
				    	foreach (@logtargets) {printf { $_ } "\tShort Radials: Calling RadialArchiver...\n";}
					## Usage: <nDiag> <cProcChar> <sOwner> <sRadFolder> <sProcFolder> <bLLUV> <bOpen> <sCfgFolder> <nPattern> <sDiagFolder>
					my $execStr = "$procToolsFolder/RadialArchiver 0 \"$shortChar\" \"RadD\" \"$CosShortRadialFolder/$CosRadSubFolder{$pattType}/\" \"$CosProcFolder/\" $outputLLUV 0 \"$configs_directory\" $patt \"$CosDiagFolder/\" 1 0 $nDopplerInterp \"\"";
					my $output = `$execStr`;
				}
				
				if ($doRads) {
				    	foreach (@logtargets) {printf { $_ } "\tStandard Radials: Calling RadialSlider...\n";}
					## RadialSlider args: <nDiagnostic> <sSuffix> <nKeepMins> <nCoverageMins> <nOutputMinutes> <bIgnoreSpan> <nOffsetMin> <sCfgFolder> <sProcFolder>
					my $execStr = "$procToolsFolder/RadialSlider 0 \"$suffix\" $timeCoverage $timeCoverage $timeOutput $IgnoreSpan $OffsetMin \"$configs_directory/\" \"$CosProcFolder/\"";
					my $output = `$execStr`;
				
					unless ($?) {  # if $? (status from most recent system call) is zero, then merge radials

						rename $CosProcFolder.$CosProcRadResult, $CosProcFolder.$outSaveBase."sr.rv";
						
						## Usage: RadialMerger <nDiag> <fSpanMinutes> <sRadListFile> <sCfgFolder> <sProcFolder>
						foreach (@logtargets) {printf { $_ } "\tStandard Radials: Calling RadialMerger...\n";}
						my $execStr = "$procToolsFolder/RadialMerger 0 $timeOutput \"$CosProcRadListFile$suffix\" \"$configs_directory/\" \"$CosProcFolder/\"";
						my $output = `$execStr`;
	
						$rt=$radType + 4;
						
						## Usage: <nDiag> <nRadType> <sProcFolder> <sDiagFolder>
						foreach (@logtargets) {printf { $_ } "\tStandard Radials: Calling RadialDiagnostic...\n";}
						$execStr = "$procToolsFolder/RadialDiagnostic 0 $rt \"$CosProcFolder/\" \"$CosDiagFolder/\" \"$configs_directory\"";
						$output = `$execStr`;
						
						## Usage: <nDiag> <cProcChar> <sOwner> <sRadFolder> <sProcFolder> <bLLUV> <bOpen> <sCfgFolder> <nPattern> <sDiagFolder>
						foreach (@logtargets) {printf { $_ } "\tStandard Radials: Calling RadialArchiver...\n";}
						$execStr = "$procToolsFolder/RadialArchiver 10 \"$oldChar\" \"RadD\" \"$CosRadialFolder/$CosRadSubFolder{$pattType}/\" \"$CosProcFolder/\" $outputLLUV 1 \"$configs_directory/\" $patt \"$CosDiagFolder/\" 0 0 $nDopplerInterp \"\"";
						$output = `$execStr`;
						$output =~ /Writing LLUV (RDL.+)/;
						foreach (@logtargets) {printf { $_ } "  **Merged radial: %s\n", $1;}
						
						## HOOK FOR STANDARD SCRIPT ##
						foreach (@logtargets) {printf { $_ } "\tCALLING HOOK...\n";}
						if (-e "/Codar/SeaSonde/Users/Scripts/NewRadial") {
							my $result = `/Codar/SeaSonde/Users/Scripts/NewRadial $CosRadialFolder/$CosRadSubFolder{$pattType} $pattType "Final"`;
							print "$result\n";
						}

						rename $CosProcRadFile,$CosProcRadSaveFile;
						copy($CosProcFolder.$CosProcRadResult,$CosProcFolder.$outSaveBase."rm.rv");
						$didRadMerge=1;

					} # unless ($?) 
				}
				copy($CosProcFolder."/RadialDiagNew.txt",$CosProcFolder."/RadialDiag.txt");
				copy($CosProcFolder."/ALim.txt",$CosProcFolder."/ALim$suffix.txt");
				copy($CosProcFolder."/FirstOrderLimits.txt",$CosProcFolder."/FirstOrderLimits$suffix.txt");
				## print "fsite = $fsite\nftime = $ftime\n";
				copy($CosProcFolder."/FirstOrderLimits.txt",$CosFirstOrderFolder."/FOL_".$fsite."_".$ftime.".txt");
				copy($CosProcFolder."/NoiseFloor.txt",$CosProcFolder."/NoiseFloor$suffix.txt");

				if (-e $CosProcFolder."/CsMark.txt")    {rename $CosProcFolder."/CsMark.txt", $CosProcFolder."/CsMark$suffix.txt";}
				if (-e $CosProcFolder."/IrMarkNew.txt") {rename $CosProcFolder."/IrMarkNew.txt", $CosProcFolder."/IrMark$suffix.txt";}
				if (-e $CosProcFolder."/IrListNew.txt") {rename $CosProcFolder."/IrListNew.txt", $CosProcFolder."/IrList$suffix.txt";}

			} ## foreach (@pattsToUse)
		} ## if ($doRads or ...)

		######################################################################
		#### #### #### ####       Wave Processing 	  #### #### #### #### #### 
		######################################################################

		if ($doWaves and $doingCSS) {

			# Usage: WaveModelForFive <nDiag> <sCfgFolder> <sOutFolder> <sProcFolder>'			
			my $execStr = "$procToolsFolder/WaveModelForFive 1 \"$configs_directory/\" \"$configs_directory/\" \"$CosProcFolder/\"";
			my $output = `$execStr`;

			if ($output =~ /Computing new wave cutoff/) {
				foreach (@logtargets) {print { $_ } "Created New WaveForFiveModel.txt\n";}
				# Copy new WMFF file to processing folder w/ time stamp on it
				copy($configs_directory."/WaveForFiveModel.txt",$CosProcFolder."/WFFM_$fsite_$ftime.txt");
				foreach (@logtargets) {print { $_ } "Copied new WaveForFiveModel.txt to $CosProcFolder/WFFM_$fsite_$ftime.txt\n";}
				}

			@filesToDelete = (	$CosProcFolder."/WaveModelData.txt",
								$CosProcFolder."/WavesModelData.txt");
			unlink @filesToDelete;

			# Look into second test argument on next line
			if (-e "$procToolsFolder/SpectraToWaveModel" and not -e "$procToolsFolder/SpectraToWavesModel") {
				## Usage: <nDiag> <sCfgFolder> <sProcFolder>
				my $execStr = "$procToolsFolder/SpectraToWaveModel 0 \"$configs_directory/\" \"$CosProcFolder/\"";
				my $output = `$execStr`;
			} else {
				## Usage: <nDiag> <sCfgFolder> <sProcFolder>
				my $execStr = "$procToolsFolder/SpectraToWavesModel 0 \"$configs_directory/\" \"$CosProcFolder/\"";
				my $output = `$execStr`;
			}

			if (-e $CosProcFolder."/WaveModelData.txt") {
				copy($CosProcFolder."/WaveModelData.txt",$CosProcFolder."/WaveModelDataSave.txt");
				}

			if (-e $CosProcFolder."/WavesModelData.txt") {
				copy($CosProcFolder."/WavesModelData.txt",$CosProcFolder."/WavesModelDataSave.txt");
				}

			## Usage: <nDiagnostic> <nKeepMins> <nCoverageMins> <nOutputMinutes> <bIgnoreSpan> <nOffsetMin> <sCfgFolder> <sProcFolder>
			$execStr = "$procToolsFolder/WaveModelSlider 0 1440 \"\" \"\" \"\" \"\" \"$configs_directory/\" \"$CosProcFolder/\"";
			$output = `$execStr`;

			unless ($?) {
				## Usage: <nDiag> <sSuffix> <sOwner> <sWaveFolder> <sProcFolder> <sCfgFolder>
				my $execStr = "$procToolsFolder/WaveModelArchiver 0 \"\" 0 \"$CosWaveFolder\" \"$CosProcFolder/\" \"$configs_directory/\"";
				my $output = `$execStr`;
			}
		} ## if ($doWaves and $doingCSS)

		##################
		# Optional Spectra Point Extraction
		##################
		if (-e $procToolsFolder."/SpectraPointExtractor" and -e $configs_directory."/SpectraPointExtractor.plist") {
		    foreach (@logtargets) {printf { $_ } "\Calling SpectraPointExtractor...\n";}
		    my $execStr = "$procToolsFolder/SpectraPointExtractor 1 \"\" $CosProcFolder";
		    my $output = `$execStr`;
		}

		##################
		# Spectra Diagnostic
		##################
		foreach (@logtargets) {printf { $_ } "\Calling SpectraDiagnostic...\n";}
		my $execStr = "$procToolsFolder/SpectraDiagnostic \"1\" \"$CosProcFolder\" \"$CosDiagFolder\" \"$configs_directory\"";
		my $output = `$execStr`;

	} ## foreach (sort @cssToProcess) 

	foreach (@logtargets) {printf { $_ } "Processing complete at %s\n", strftime($logdatefmt, localtime);}
	foreach (@logtargets) {printf { $_ } "%.1f minutes total processing time\n", (time - $^T)/60;}

} else { ## if ($#cssToProcess >= 0) 
	foreach (@logtargets) {print { $_ } "Sorry, no $proc_file_prefix files to process.\n";}
}

foreach (@logtargets) {print { $_ } "\n";}

close LOG;

__END__

=head1 NAME

 This script is intended to streamline reprocessing of CODAR Ocean Sensors cross spectra files into radials or waves.

=head1 SYNPOSIS

 batch_reprocess_css.pl --source_directory=/my/css/files --target_directory=/my/output/directory \
                        --start_time="2011/11/11 11:11" --stop_time="2012/12/12 12:12"\
                        --configs_directory=/codar/radaial/configs/

=head2 REQUIRED INPUTS

=over 8

=item B<source_directory>

folder is the top folder of the entire tree to search for CSS (input) files

=item B<start_time>

date string (starting)	only data occurring after date text string shall be processed
format: "yyyy/mm/dd HH:MM"

=item B<stop_time>

date string (stopping) only data occurring before date text string shall be processed
format: "yyyy/mm/dd HH:MM"

=back

=head2 OPTIONAL INPUTS

=over 8

=item B<target_directory>

target folder under which a subfolder specific to this instance of reprocessing

=item B<proc_file_prefix>

text (CSS_ or CSS_XXXX or CSS_XXXX_07_08_) filter files by matching the text at the beginning of the filenames -> default: 'css'

=item B<proc_file_suffix>

filter files by matching the text at the end of the filenames -> default: '.cs4'

=item B<configs_directory>

directory (RadialConfigs) containing the config files to be used -> default: /codar/seasonde/configs/radialconfigs

=item B<binary_directory>

directory (SpectraProcessing) containing the processing tools to be used -> default: /codar/seasonde/apps/radialtools/spectraprocessing

=back

=head1 DESCRIPTION

  This perl script is intended for the B<reprocessing> of CODAR Ocean Sensors (COS) cross spectra (I<CSS>)
  files into radial and/or wave measurement files using standard and proprietary COS SeaSonde Radial Suite
  Software.

  Script will attempt to keep current with latest COS SeaSonde Radial Suite, but the user should make sure 
  to double check this with his/her version of COS software with the version release notes of this script
  before attempting to use this script.

=head1 AUTHOR

  Daniel Patrick Atwater
  L<danielpath2o@gmail.com>

=head1 VERSION

=over 8

=item version 0.1

 08 April 2005
 working version, SeaSonde Software Release 4

=item version 0.2

 17 November 2007
 updated to be compliant with SeaSonde Software Release 5
 usage added

=item version 0.3

 06 September 2010
 updated to be compliant with SeaSonde Software Release 6

=item version 0.4

 21 July 2012
 updated to be compliant with SeaSonde Software Release 7

=back

=head1 COPYRIGHT

Copyright: General Public License (GPL), Daniel Patrick Atwater 2009

=cut
