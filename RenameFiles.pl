#!/usr/local/bin/perl -w

#version 19-10-2018


# ------------------------ Gebruik ---------------------------------------------------------------------------------------------------#
#
# dit perl-script wordt gebruikt om bestanden massaal te hernoemen naar een vast formaat, dat ziet er als volgt uit:
#              20100309-120501 Onderwep van de foto.jpg
# 
# Daar zijn variaties op mogelijk:
#              20100309-001 Onderwerp van de foto.jpg
#              Geen datum-001 Onderwerp van de foto.jpg
#
#
# Maak daartoe een bestand aan met de naam start.xml en plaats deze in de map waar de bestanden staan, die hernoemd moeten worden
# Als het script voltooid is, dan wordt het bestand start.xml hernoemd naar stop.xml. Alleen als dit bestand start.xml heet, dan
# worden de bestanden daadwerkelijk hernoemd.
#
#
# de inhoud van het bestand start.xml ziet er als volgt uit:
#
# - config:	verplicht	1		alle tags binnen de hoofdtag <config>  ... </config>, geen additionele attributen
# - alias:			0 of meer	er kunnen meerdere alias-tags worden aangemaakt
#		- titel:	verplicht		naam van de exif-tag
#		- default:				de standaardwaarde indien exif onder ondewerp niet voorkomt of niet is gevuld met een waarde
#		- type:					als deze datum is dan wordt de datum met deze waarde opgeteld of afgetrokken
#		- content:	verplicht		de alias zelf, deze mag vaker voorkomen
# - convert:   verplicht	1 of meer	per zoekopdracht
# 		- filter:    	verplicht		hierin staat de zoekopdracht welke bestanden je wilt hernoemen, bv *.jpg
# 		- nummering: 			T	geeft aan hoe je de bestanden na de datum notatie genummerd wilt hebben, 
#              						bijvoorbeeld: 20100309-001
#              	- posities: 			3	in dat geval geef je het startnummer op, in dit geval 1 en attribuut "posities" 3, betekent het nummer 
#                          				uitvullen tot 3 cijfers, voordat er genummerd wordt, worden alle bestanden alfabetisch gesorteerd in 
#                          				oplopende volgorde indien je geen nummer, maar het tijdstip wilt in uren, minuten en seconden, dan geef
#                          				je in plaats van een cijfer de waarde T op. In plaats van 20100309-001 staat er dan 20100309-120501. 
#              	- sub:      			a	Het kan zijn dat er binnen één seconde meer dan één foto is genomen, dan komt er bij de volgende foto 
#                          				een a te staan achter de nummering, bijvoorbeeld: 20100309-001a of 20100309-120501a, de daaropvolgende
#                          				foto wordt b, etc. Met het attribuut "sub" kun je de startwaarde hiervan wijzigen
#		- voorloop						In plaats van een datum kan ook gekozen worden voor een vaste voorloopstring
# 		- datum:     			DateTimeOriginal	Als dit attribuut er niet is, dan wordt geprobeerd om de DateTimeOriginal waarde 
#									van de exif informatie in het bestand op te halen. Als dat niet lukt, dan wordt de waarde
#									leeg gelaten. Als je toch een waarde wilt, dan vul je een standaardwaarde in.
#              	- exif-datum:			DateTimeOriginal	dit attribuut geeft aan welke exif-waarde je wilt ophalen. Standaard is dat DateTimeOriginal, 
#									maar dat mag ook een andere waarde zijn
#              	- exif-datumformaat:		%Y:%m:%d %H:%M:%S	mocht het formaat binnen de exif of de DateTime afwijken van %Y:%m:%d %H:%M:%S, dan kun je 
#									deze in  dit attribuut aanpassen
#		- exif-timezone:		TimeZone		dit attribuut kan ingesteld worden als een timezone wordt gebruikt om de interne tijd te corrigeren
#              	- patroon:     			%Y%m%d%H%M%S		mocht er geen exif-informatie zijn, dan kan de bestandsnaam gebruikt worden om daaruit 
#									de datum en tijdstip te extraheren, bijvoorbeeld %Y%m%d%H%M%S, dit patroon komt overeen 
#									met 20100309120501.
#                             						staat er ook geen tijdstip in de bestandsnaam, dan kan nog geprobeerd worden om de 
#									aanmaakdatum (CreateDateTime), de wijzig datum (ModifyDateTime) of de open datum
#									(AccessDateTime) te gebruiken. Deze 3 waardes kun je dan zetten in het attribuut "patroon"
#              	- overschrijf: 			nee			tenslotte kun je forceren om de waarde in de attribuut datum te gebruiken door dit 
#                             						attribuut op ja te zetten, in dit geval wordt nog steeds de teller gebruikt om door te
#									tellen en/of de sub-teller om door te nummeren. Er wordt namelijk voorkomen om een bestand
#									te hernoemen naar een reeds bestaand bestand
# - onderwerp:	verplicht	1 of meer	Dit is vooral handig als je op basis van datum en tijdstip bestanden een juist onderwerpsnaam wilt geven.
#              	- exif-titel: 						het is mogelijk om het onderwerp uit de exif-informatie te halen. Hier geef je aan welke
#									exif-waarde je daarvoor wilt gebruiken. Mocht deze waarde niet gevuld zijn, dan wordt de 
#									waarde het attribuut titel gebruikt
#              	- overschrijf-titel: 		nee			mocht je altijd de waarde van het attribuut titel willen gebruiken, dan geef je dit attribuut 
#									de waarde ja
#              	- tijd-start:  						per onderwerp regel kun je aangeven wat het start tijdstip is en het eindtijdstip, dit geef 
#									je aan in het formaat yyyy-mm-dd hh:MM:ss, de uren, minuten en seconden kun je weglaten.
#                             						de datum die hiervoor gebruikt wordt, heb je hiervoor bepaald en is de datum , die uiteindelijk 
#                             						gebruik wordt om het bestand te hernoemen.
#              	- tijd-einde:  						werkt hetzelfde als tijdstart, maar geeft het eindtijdstip aan. Je kunt alleen een tijdstart 
#									opgeven zonder tijdeinde en omgekeerd.
#		- datumshift:						hiermee kun je de datum corrigeren in uren, minuten en seconden voor- of achteruit
#		- titel:						de naam van het onderwerp indien deze niet uit de exif-informatie komt
# - exif:	niet verplicht	0 of meer	per onderwerp kunnen meerdere tags exif voorkomen. De exif-informatie wordt weggeschreven in het bestand
#		- titel:	verplicht				exif-waarde, tenzij alias-titel is gevuld, dat kan van het type EXIF zijn, of XMP of IPTC
#		- alias-titel:	verplicht				indien titel niet gevuld, dan is deze waarde verplicht
#									de waarde wordt gezocht in de aliassen zoals in de alias-tags is gedefinieerd, er kunnen 
#									meerder aliassen met dezelfde naam voorkomen, elke exif-tag wordt dan voorzien van de content 
#									van exif
#		- type:							dit hoeft alleen gebruikt en gevuld te worden, indien de exif-waarde een datumveld is, hiermee
#									kan een datum en tijdstip in uren, minuten en seconden nauwkeurig worden gecorrigeerd. Dit 
#									attribuut is niet nodig indien de alias-titel gebruikt wordt en het type onder de alias al is 
#									gevuld
#		- content:	verplicht				de waarde van de exif-tag in het bestand
#
# Mocht er iets fout gaan, dan wordt dit weggeschreven in het bestand fouten.txt in dezelfde map als de bestanden.
# Er wordt ook bijgehouden of alle bestanden zoals je die in de zoekopdracht hebt meegegeven wel hernoemd zijn. Als er een bestand
# niet hernoemd is, dan wordt dit in het foutenbestand opgenomen.
# Het kan ook zijn, dat de exif-waarde niet is gevonden, dan wordt geprobeerd om in het foutenbestand alle mogelijk exif-labels en
# waardes weer te geven.
#
# ------------------------------------------------------------------------------------------------------------------------------------#


# use module
use strict;
use warnings;

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
	my $self = shift;
	my $type = shift;
	my $text = "";
	my $errortype = "";
	foreach my $errorline (@Errorlines) {
#		if ($errorline->{errortype} >= $type) {
			if ($errorline->{errortype} == DEBUG) {
				$errortype = "DEBUG";
			} elsif ($errorline->{errortype} == WARNING) {
				$errortype = "WARNING";
			} else {
				$errortype = "ERROR";
			}
			$text = $text . sprintf("%-30s %-10s %-100s\n", $errorline->{file}, $errortype, $errorline->{errormessage});
#		}
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
	my $format = "%-40s %-50s\n";
	print sprintf($format, "Folder", $folder);
	print sprintf($format, "Folder start.xml", $folderxml);
	print sprintf($format, "Folder errors.txt", $foldererror);
	if ($clearfile eq false) {
		print sprintf($format, "Clean up errors.txt", "no");
	} else {
		print sprintf($format, "Clean up errors.txt", "ja");
	}
	if ($norename eq false) {
		print sprintf($format, "Rename", "yes");
	} else {
		print sprintf($format, "Rename", "no");
	}
}
	


# maak foutenbestand
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
my $todaystring = sprintf("%04d-%02d-%02d %02d:%02d:%02d", localtime->year()+1900, localtime->mon()+1, localtime->mday(), localtime->hour(), localtime->min(), localtime->sec());

# lees alle waardes voor aliassen in. Deze array vormt de basis voor het vullen van de exif-informatie in het bestand
# titel:	titel van de exif-tag
# default:	indien geen waarde opgegeven bij de exif van het onderwerp, dan wordt de default waarde ingevuld
# alias:	de alias die verderop bij de exif van het onderwerp gebruikt kan worden (aliastitel) in plaats van de exif-tag
# value:	deze waarde is in beginsel leeg, maar wordt later ingevuld zoals opgegeven in exif onder onderwerp
# type:		als het type datum is dan wordt een datumbewerking uitgevoerd (optellen of aftrekken van uren, minuten, seconden
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
				$renamefileobject->write_exiftags($alias);
				if ($convertobject->iscounter()) {
					$numbering = $count;
				}
				$renamefileobject->setrename($norename eq false);
				$renamefileobject->rename($subjectobject->title($renamefileobject->title()), $numbering, $convertobject->subchar());
			}
			
			$count++;
			push @Errorlines, $renamefileobject->errors();
		}
		push @Errorlines, $subjectobject->errors();
	}
	push @Errorlines, $convertobject->errors();
}

print $errorfile printerrors(DEBUG);

close($errorfile);