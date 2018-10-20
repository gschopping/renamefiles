#!/usr/local/bin/perl -w

#version 19-10-2018


# ------------------------ Usuage ---------------------------------------------------------------------------------------------------#
#
# This Perl script is created in order to rename a bundle of files (can be phot, video, audio) in an approopriate format:
# 		20100309-120501 Description.jpg
# 
# However other variations are possible as well:
#		20100309-001 Description.jpg
#		Description.jpg
#		NoDate-001 Description.jpg
#
# Where possible it retrieves the information within the files with the help of exiftool, but it can also retrieve the date and time
# from the pattern of the filename.
#
# The configuration is made with an xml-file: start.xml whcih you can place in the same directory as the files
# All files should be in one folder
#
#
# The content of the start.xml file should look like:
# ==============================================================================================================================================================
# level	tagname	compulsory	number		description
# ==============================================================================================================================================================
# 1	config	yes		1		all tags should be enclosed within the maintag <config> ... </config>, no additional attributes
# 2	alias	no		0 or more	an alias is an easy way to set a set of exif-tags at once, and it's easier to remember, since you put all aliases
#						one time
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
# 		attribute	default	description
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
#		title				name of the exif-tag (groupname:tagname)
#		default				if the alias is not set at subject-level, the default value is used
#		type				only necessary if it is of type datetime, in that case the value in this tag is taken as relative to the current
#						date and time
#		content				the value between the tagnames, the alias itself, this can be any name as you wish, and can be used further on
#						you can als use the same alias for multiple exif-tags
# ==============================================================================================================================================================
# level	tagname	compulsory	number		description
# ==============================================================================================================================================================
# 2	convert	yes		1 or more	you set this tag for each search, a search is done like you do dir, eg *.jpg to find all files ending on .jpg
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
# 		attribute		default		description
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
#		filter			*.JPG		the search for files
#		numbering		T		a number:	this is the starting number for the file, when you want a sequence of numbers in stead of a time
#							T		instead of a number you take the time of the file
#		positions		3		if not set, it pads the number with zeros up to 3 digits
#		subchar			a		default is "a", in case two file will be renamed to the same name, it adds "a" after the number ot time in order
#							to avoid overwriting of files. You can set to any character you want
#		prefix					instead of datetime you can use a fixed prefix
#		overwrite_prefix 	no		Force to use prefix instead of datetime, even if it can be found in the exif-information
#		exif-title		Title		name of the tag where to find the title for the description of the file
#		exif-datetime		DateTimeOriginal name of the tag where to find the datetime of the file
#		exif-datetimeformat	%Y:%m:%d %H:%M:%S the is the standard format, it's very unlikely to change it
#		exif-timezone		TimeZone	name of the tag where to find the timezone (if any) in the file
#		exif-timezoneformat	%H:%M		standard format, it's unlikely to change it
#		pattern			%Y%m%d_%H%M%S	sometimes the file doesn't have exif-info, but has the datetime information in the filename
# ==============================================================================================================================================================
# level	tagname	compulsory	number		description
# ==============================================================================================================================================================
# 3	subject	yes		1 or more	within the subject to you can differentiate files by timing. In a certain timeframe you can set another description
#						for the file
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
# 		attribute	default		description
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
#		title				the description for a file
#		overwrite-title	no		you can force to use the title for the description instead of retrieving it from the exif-info
#		datetime-start	no		the datetime of a file should be more or equal to this value (can be dd-mm-yyyy or dd-mm-yyyy hh:mm:ss)
#		datetime-end	no		the datetime of a file should be less than this value (can be dd-mm-yyyy or dd-mm-yyyy hh:mm:ss)
#		timeshift	no		in case you set the time wrong you can shift the time in hh:mm:ss
# ==============================================================================================================================================================
# level	tagname	compulsory	number		description
# ==============================================================================================================================================================
# 4	exif	no		0 or more	if you want to write predefined information back into the exif-information of a file (makes the renaming slower)
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
# 		attribute	default		description
# --------------------------------------------------------------------------------------------------------------------------------------------------------------
#		title				exif tagname unless alias is used
#		alias-title			instead of exif tagname you can use the alias as set in the top of the config-file
#		type				in case of a datetime field set it to datetime
#		content				between tage, the value of the tagname with which the exif-info will be set
#
# In case of an error the information will be written in the file errors.txt in the same folder as the files
#
# ------------------------------------------------------------------------------------------------------------------------------------#


# use module
use strict;
use warnings;
our $VERSION = '1.0';


use Image::ExifTool ':Public';
use Time::localtime;
use XML::Simple;
use DateTime::Format::Strptime;
use File::stat;
use Getopt::Std;
use RenameFiles::Convert;
use RenameFiles::Subject;
use RenameFiles::RenameFile;
use RenameFiles::Aliases;
use constant { true => 1, false => 0 };
use constant { ERROR => 2, WARNING => 1, DEBUG => 0};


my @Errorlines = ();

sub printerrors {
	my $type = shift;
	if (! defined $type) {
		$type = DEBUG;
	}
	my $todaystring = sprintf("%04d-%02d-%02d %02d:%02d:%02d", localtime->year()+1900, localtime->mon()+1, localtime->mday(), localtime->hour(), localtime->min(), localtime->sec());
	my $text = "";
	my $errortype = "";
	foreach my $errorline (@Errorlines) {
		if ($errorline->{errortype} >= $type) {
			if ($errorline->{errortype} == DEBUG) {
				$errortype = "DEBUG";
			} elsif ($errorline->{errortype} == WARNING) {
				$errortype = "WARNING";
			} else {
				$errortype = "ERROR";
			}
			$text = $text . sprintf("%-20s %-30s %-10s %-100s\n", $todaystring, $errorline->{file}, $errortype, $errorline->{errormessage});
		}
	}
	return $text;
}


# you can set as parameter
#	-d	debug
#	-n	no rename (only show output without actually renaming
#	-x	location for start.xml
#	-f	folder for the files to be renamed
#	-e	location for the errors.txt
#	-c 	clean up before adding errors.txt

use vars qw/$opt_d/;
use vars qw/$opt_n/;
use vars qw/$opt_x/;
use vars qw/$opt_f/;
use vars qw/$opt_e/;
use vars qw/$opt_c/;

my $debug = false;
getopt('d');
if (defined $opt_d) {
	$debug = true
}

my $norename = false;
getopt('n');
if (defined $opt_n) {
	$norename = true;
}

my $clearfile = false;
getopt('c');
if (defined $opt_c) {
	$clearfile = true;
}

getopt('f');
my $folder = shift || "X:/Onbewerkt/";

getopt('x');
my $folderxml = shift || $folder;

getopt('e');
my $foldererror = shift || $folder;


if ($debug eq true) {
	my $format = "%-20s %-30s\n";
	printf("$format", "Folder", $folder);
	printf("$format", "Folder start.xml", $folderxml);
	printf("$format", "Folder errors.txt", $foldererror);
	if ($clearfile eq false) {
		printf("$format", "Clean up errors.txt", "no");
	} else {
		printf("$format", "Clean up errors.txt", "yes");
	}
	if ($norename eq false) {
		printf("$format", "Rename", "yes");
	} else {
		printf("$format", "Rename", "no");
	}
}
	


# create errofile
my $errorfile;
if ($clearfile eq false) {
	open($errorfile, '>>', $foldererror . 'errors.txt') or die printf("Can't open %s\n", $foldererror . "errors.txt");
} else {
	open($errorfile, '>', $foldererror . 'errors.txt') or die  printf("Can't open %s\n", $foldererror . "errors.txt");
}



# create object
my $xml = XML::Simple->new;

# read XML file
my $data = $xml->XMLin($folderxml . 'start.xml', ForceArray => ['convert', 'alias', 'subject']) or die $errorfile;

my $alias;
foreach my $aliastag (@{$data->{alias}}) {
	$alias = RenameFiles::Aliases->new("title" => $aliastag->{title}, "default" => $aliastag->{default}, "alias" => $aliastag->{content}, "type" => $aliastag->{type});
}


foreach my $convert (@{$data->{convert}}) {
# take convert tag from xml-file
	my $convertobject = RenameFiles::Convert->new("numbering" => $convert->{numbering}, "positions" => $convert->{positions}, 
		"exif_datetime" => $convert->{"exif-datetime"}, "exif_datetimeformat" => $convert->{"exif-datetimeformat"}, "pattern" => $convert->{pattern},
		"exif_title" => $convert->{"exif-title"}, "overwrite_prefix" => $convert->{"overwrite-prefix"}, "folder" => $folder, "debug" => $debug,
		"filter" => $convert->{filter}, "exif_timezone" => $convert->{"exif-timezone"}, "exif_timezoneformat" => $convert->{"exif-timezoneformat"});
	my $count = $convertobject->counter();
	
	foreach my $subject (@{$convert->{subject}}) {
		my $subjectobject = RenameFiles::Subject->new("overwrite_title" => $subject->{"overwrite-title"}, "title" => $subject->{"title"},
			"datetime_start" => $subject->{ "datetime-start"}, "datetime_end" => $subject->{"datetime-end"}, "timeshift" => $subject->{"timeshift"});
		$convertobject->setdebug($convertobject->filter(), "Subject", $subject->{title});
# clear all values in alias array
		if (defined $alias) {
			$alias->clearall();
	# the values in the alias array will be filled from the values in the exif tags
			foreach my $exif (@{$subject->{exif}}) {
				$convertobject->setdebug($convertobject->filter(), "Exif", $exif->{"alias-titel"});
				my $found = false;
				if ((defined $exif->{"alias-title"}) && (defined $exif->{content})) {
					$found = $alias->setvalue_for_alias($exif->{"alias-title"}, $exif->{content});
				} elsif ((defined $exif->{title}) && (defined $exif->{content})) {
					$found = $alias->setvalue_for_title($exif->{title}, $exif->{content});
					if ($found eq false) {
						$alias = Aliases->new("title" => $exif->{"alias-title"}, "default" => undef, "value" => $exif->{content}, "type" => $exif->{type});
					}
				} else {
					$alias = Aliases->new("title" => $exif->{"alias-title"}, "default" => undef, "value" => $exif->{content}, "type" => $exif->{type});
				}

			}
		}
	# read files for filter
		my @files = $convertobject->getfiles();
		my $count = $convertobject->counter();
		my $numbering = $convertobject->numbering();
		foreach my $file (@files) {
			my $renamefileobject = RenameFiles::RenameFile->new("filename" => $file, "positions" => $convertobject->positions(),
				"prefix" => $convertobject->prefix(), "exif_title" => $convertobject->exif_title(), "exif_datetime" => $convertobject->exif_datetime(),
				"exif_datetimeformat" => $convertobject->exif_datetimeformat(), "exif_timezone" => $convertobject->exif_timezone(),
				"exif_timezoneformat" => $convertobject->exif_timezoneformat(), "pattern" => $convertobject->pattern(),
				"overwrite_prefix" => $convertobject->overwrite_prefix());
			$renamefileobject->set_exiftags($alias);
			$renamefileobject->settimeshift($subjectobject->timeshift(), $subjectobject->timeshift_sign());
			if ($subjectobject->is_file_within_dateperiod($renamefileobject->corrected_datetime())) {
				$renamefileobject->setrename($norename eq false);
				$renamefileobject->write_exiftags($alias);
				if ($convertobject->iscounter()) {
					$numbering = $count;
				}
				$renamefileobject->rename($subjectobject->title($renamefileobject->title()), $numbering, $convertobject->subchar());
				if ($debug eq true) {
					print $renamefileobject->print();
				}
			}
			
			$count++;
			push @Errorlines, $renamefileobject->errors();
		}
		push @Errorlines, $subjectobject->errors();
	}
	push @Errorlines, $convertobject->errors();
}

if ($debug eq true) {
	print $errorfile printerrors(DEBUG);
} else {
	print $errorfile printerrors(WARNING);
}

close($errorfile);