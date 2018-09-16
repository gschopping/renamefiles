#!/usr/local/bin/perl -w

#versie 04-03-2017

# Wijzigingen
# Datum			Omschrijving
# 07-01-2014	Subnummering toegevoegd
# 20-03-2015	DateTimeOriginal en format voor exif
# 25-04-2015	Conditie op basis van datum/tijdstip
# 19-02-2016	datum/tijd ophalen uit bestand: tijdstip van aanmaken, wijzigen of toegang
# 11-09-2016	tags filter en nummering onderbrengen onder filter, nieuwe tag exif
# 27-11-2016	alias toegevoegd, waarmee het eenvoudiger wordt exif informatie aan de foto/video toe te voegen
# 03-12-2016	objecten Alias en Bestand toegevoegd
# 04-03-2017	Check of bestand met exif-informatie geschreven kan worden (CanWrite) en check of tags schrijfbaar zijn (GetWritableTags)
# 26-03-2017	Nieuw object EenBestand toegevoegd en van de aparte packegs modules gemaakt (C:\Dwimperl\perl\site\lib\My)
# 07-07-2017	onderwerp leegmaken aan einde van for loop
# 27-01-2018	foutje hersteld in hernoemen indien bestand bestaat (met subnummering)

# TO DO
# 09-09-2018	TimeZone meenemen in tijdsbepaling. Tevens timeshift indien van toepassing vooraf calculeren alvorens vergelijken met begin- en eindtijd
#		Daarmee wordt de begin- en eindtijd niet afhankelijk van de verkeerde tijd in het bestand
#		Meer foutcontroles uitvoeren: begintijd moet vóór eindtijd liggen, tijdstippen moeten voldoen aan correct formaat
#		Controle op alle tags, of die bestaan en melden als een onbekende tag wordt gebruikt

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
use RenameFiles::EenBestand;
use RenameFiles::Bestand;
use RenameFiles::Alias;

# meegeven als parameter
#	-d	debug
#	-n	no rename (alleen uitvoer tonen,niet wijzigen
#	-x	locatie start.xml
#	-f	map waar de te hernoemen bestanden staan
#	-e	locatie fouten.txt
#	-c 	opschonen fouten.txt

use vars qw/$opt_d/;
use vars qw/$opt_n/;
use vars qw/$opt_x/;
use vars qw/$opt_f/;
use vars qw/$opt_e/;
use vars qw/$opt_c/;

my $debug = 0;
getopt('d');
if (defined $opt_d) {
	$debug = 1
}

my $norename = 0;
getopt('n');
if (defined $opt_n) {
	$norename = 1;
}

my $clearfile = 0;
getopt('c');
if (defined $opt_c) {
	$clearfile = 1;
}

getopt('f');
my $map = shift || "X:/Onbewerkt/";

getopt('x');
my $mapxml = shift || $map;

getopt('e');
my $maperror = shift || $map;


# lege waarde
my $leeg = "[leeg]";
# my $default_extensie = "JPG";
# my $default_exifdatum = "DateTimeOriginal";
# my $default_exifdatumformaat = "%Y:%m:%d %H:%M:%S";
# my $default_datum = "Vandaag";
# my $default_voorloop = "Vandaag";
my $default_subwaarde = "a";
# my $default_posities = 3;

my $mapdir = $map;
if (substr($mapdir, -1) eq "/") {
	$mapdir =~ s/.{1}$//;
}


if ($debug == 1) {
	print "map:\t\t\t$mapdir\n";
	print "map start.xml:\t\t$mapxml\n";
	print "map fouten.txt:\t\t$maperror\n";
	if ($clearfile == 0) {
		print "fouten.txt opschonen:\tnee\n";
	} else {
		print "fouten.txt opschonen:\tja\n";
	}
	if ($norename == 0) {
		print "Hernoemen:\t\tja\n";
	} else {
		print "Hernoemen:\t\tnee\n";
	}
}
	


# maak foutenbestand
my $errorfile;
if ($clearfile == 0) {
	open($errorfile, '>>', $maperror . 'fouten.txt') or die "Kan " . $maperror . "fouten.txt niet openen\n";
} else {
	open($errorfile, '>', $maperror . 'fouten.txt') or die "Kan " . $maperror . "fouten.txt niet openen\n";
}



# create object
my $xml = XML::Simple->new;

# read XML file
my $data = $xml->XMLin($mapxml . 'start.xml', ForceArray => ['convert', 'alias', 'onderwerp']) or die $errorfile;
my $vandaagstring = sprintf("%04d-%02d-%02d %02d:%02d:%02d", localtime->year()+1900, localtime->mon()+1, localtime->mday(), localtime->hour(), localtime->min(), localtime->sec());

# lees alle waardes voor aliassen in. Deze array vormt de basis voor het vullen van de exif-informatie in het bestand
# titel:	titel van de exif-tag
# default:	indien geen waarde opgegeven bij de exif van het onderwerp, dan wordt de default waarde ingevuld
# alias:	de alias die verderop bij de exif van het onderwerp gebruikt kan worden (aliastitel) in plaats van de exif-tag
# value:	deze waarde is in beginsel leeg, maar wordt later ingevuld zoals opgegeven in exif onder onderwerp
# type:		als het type datum is dan wordt een datumbewerking uitgevoerd (optellen of aftrekken van uren, minuten, seconden
my $alias;
foreach my $aliastag (@{$data->{alias}}) {
	my $alias_titel = $aliastag->{titel} || $leeg;
	my $alias_default = $aliastag->{default} || $leeg;
	my $alias_value = $aliastag->{content} || $leeg;
	my $alias_type = $aliastag->{type} || $leeg;
	$alias = My::Alias->new("titel" => $alias_titel, "default" => $alias_default, "alias" => $alias_value, "type" => $alias_type);
}

if (! chdir $mapdir) {
	print "Map is niet gewijzigd\n";
}
# system("dir");

my $bestand;
foreach my $convert (@{$data->{convert}}) {
# bepaal waardes uit xml-bestand
	$bestand = My::Bestand->new("nummering" => $convert->{nummering}, "posities" => $convert->{posities}, 
		"exifdatum" => $convert->{"exif-datum"}, "exifdatumformaat" => $convert->{"exif-datumformaat"}, "patroon" => $convert->{patroon},
		"exiftitel" => $convert->{"exif-titel"}, "overschrijfvoorloop" => $convert->{"overschrijf-voorloop"}, "map" => $map, "debug" => $debug,
		"filter" => $convert->{filter});
	
	foreach my $onderwerp (@{$convert->{onderwerp}}) {
		$bestand->setdebug($convert->{filter}, "Onderwerp", $onderwerp->{titel});
# maak alle waardes in de alias-array leeg
		if (defined $alias) {
			$alias->clearall();
	# de waardes in de aliasarray wordt aangevuld met de waardes van exif
			foreach my $exif (@{$onderwerp->{exif}}) {
				$bestand->setdebug($convert->{filter}, "Exif", $exif->{"alias-titel"});
				my $exif_alias = $exif->{"alias-titel"} || $leeg;
				my $exif_titel = $exif->{titel} || $leeg;
				my $exif_value = $exif->{content} || $leeg;
				my $exif_type = $exif->{type} || $leeg;
				if (($exif_alias ne $leeg) && ($exif_titel eq $leeg)) {
					$alias->value_for_alias($exif_alias, $exif_value);
				} else {
					my $found = $alias->value_for_titel($exif_titel, $exif_value);
					if ($found == 0) {
						$alias = Alias->new("titel" => $exif_titel, "default" => $leeg, "value" => $exif_value, "type" => $exif_type);
					}
				}
			}
		}
	
		my @files = $bestand->geefbestanden($onderwerp->{"tijd-start"}, $onderwerp->{"tijd-einde"}, $onderwerp->{titel}, 
			$onderwerp->{"overschrijf-titel"}, $onderwerp->{datumshift});
		foreach my $file (@files) {
			if (defined $alias) {
				my $exiftool = new Image::ExifTool;

		# wijzig de exif-attributen in het bestand
				my $schrijfexif = 0;
				$exiftool->SaveNewValues();
				my $success;
				foreach my $exifvalue ($alias->aliases()) {
					if ($exifvalue->waarde() ne $leeg) {
						if ($exifvalue->type() eq "datum") {
							$success = $exiftool->SetNewValue($exifvalue->titel() => $exifvalue->abswaarde(), Shift => $exifvalue->datumshift());
							$bestand->setdebug($file->bestand(), "Exiftool:SetNewValue", $exifvalue->titel() . ", " . $exifvalue->waarde() . ", " . $exifvalue->datumshift());
						} else {
							$success = $exiftool->SetNewValue($exifvalue->titel() => $exifvalue->waarde());
							$bestand->setdebug($file->bestand(), "Exiftool:SetNewValue", $exifvalue->titel() . ", " . $exifvalue->waarde());
						}
						if (! $success) {
							$bestand->seterror($file->bestand(), "exif", "Kan " . $exifvalue->titel() . ", " . $exifvalue->waarde() . " niet schrijven (1)");
						} else {
							$schrijfexif = 1;
							$exifvalue->geschreven();
						}
		# vul de exif-waardes in als de exif-tag overeenkomt met de definitie in convert
						if ($exifvalue->isexif_titel($convert->{"exif-titel"})) {
							$file->settitel_exif($exifvalue->waarde());
						}
						if ($exifvalue->isexif_datum($convert->{"exif-datum"})) {
							$file->setdatumshift_exif($exifvalue->waarde());
						}

					}
				}
				if (($schrijfexif == 1) && ($norename == 0)) {
					$success = $exiftool->WriteInfo($file->bestand());
					$file->setschrijfexif($success);
					if ($success != 1) {
		# nogmaal schrijven maar dan tag voor tag, een stuk langzamer,maar dat moet dan maar
						$exiftool->RestoreNewValues();
						foreach my $exifvalue ($alias->aliases()) {
							if ($exifvalue->waarde() ne $leeg) {
								if ($exifvalue->type() eq "datum") {
									$success = $exiftool->SetNewValue($exifvalue->titel() => $exifvalue->abswaarde(), Shift => $exifvalue->datumshift());
									$bestand->setdebug($file->bestand(), "Exiftool:SetNewValue", $exifvalue->titel() . ", " . $exifvalue->waarde() . ", " . $exifvalue->datumshift());
								} else {
									$success = $exiftool->SetNewValue($exifvalue->titel() => $exifvalue->waarde());
									$bestand->setdebug($file->bestand(), "Exiftool:SetNewValue", $exifvalue->titel() . ", " . $exifvalue->waarde());
								}
								if (! $success) {
									$bestand->seterror($file->bestand(), "exif", "Kan " . $exifvalue->titel() . ", " . $exifvalue->waarde() . " niet schrijven (2)");
								} else {
									$success = $exiftool->WriteInfo($file->bestand());
									$file->setschrijfexif($success);
									if ($success != 1) {
										$bestand->seterror($file->bestand(), "exif", "Kan exif-waarde " . $exifvalue->titel() . " niet schrijven (3)");
										$exifvalue->nietgeschreven();
									}
								}
							}
						}
					}
				}
			}
			# print $file->print();
			
			my $voorloopstring = $file->voorloopstring();
			my $omschrijving = $file->titel();
			if (($voorloopstring ne "") && ($omschrijving ne "")){
				$voorloopstring = $voorloopstring . " ";
			}
			my $subvoorloopstring = $file->voorloopstring();
			
			my $newfile;
			unless (-e $map. $voorloopstring . $omschrijving . "." . $file->extensie()) {
				$newfile = $voorloopstring . $omschrijving . "." . $file->extensie();
				print $file->bestand() . " =>\t$newfile\n";
				$bestand->seterror($file->bestand(), "rename", $newfile);
				$newfile = $map . $newfile;
				if ($norename == 0) {
					rename $file->bestandplusmap(), $newfile;
				}
			} else {
				my $subtemp = $convert->{sub} || $default_subwaarde;
				$subvoorloopstring = $subvoorloopstring . $subtemp;
				if (($subvoorloopstring ne "") && ($omschrijving ne "")){
					$subvoorloopstring = $subvoorloopstring . " ";
				}
				while (-e $map . $subvoorloopstring . $omschrijving . "." . $file->extensie()) {
					$subtemp = chr(1 + ord $subtemp);
					$subvoorloopstring = $file->voorloopstring();
					$subvoorloopstring = $subvoorloopstring . $subtemp;
					if (($subvoorloopstring ne "") && ($omschrijving ne "")){
						$subvoorloopstring = $subvoorloopstring . " ";
					}
				}
				$newfile = $subvoorloopstring . $omschrijving . "." . $file->extensie();
				print $file->bestand() . " =>\t$newfile\n";
				$bestand->seterror($file->bestand(), "rename", $newfile);
				$newfile = $map . $newfile;
				if ($norename == 0) {
					rename $file->bestandplusmap(), $newfile;
				}
			}
			# print "-------------------------------------------\n";
			# print "\n";
		
		}
	}
}
$bestand->printerrorfile($errorfile, $vandaagstring);
$bestand->clearall();

close($errorfile);