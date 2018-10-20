package RenameFiles::Convert;

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
#              	- exif-titel: 						het is mogelijk om het onderwerp uit de exif-informatie te halen. Hier geef je aan welke
#									exif-waarde je daarvoor wilt gebruiken. Mocht deze waarde niet gevuld zijn, dan wordt de 
#									waarde het attribuut titel gebruikt
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
#              	- overschrijf-voorloop: 	nee			tenslotte kun je forceren om de waarde in de attribuut datum te gebruiken door dit 
#                             						attribuut op ja te zetten, in dit geval wordt nog steeds de teller gebruikt om door te
#									tellen en/of de sub-teller om door te nummeren. Er wordt namelijk voorkomen om een bestand
#									te hernoemen naar een reeds bestaand bestand
# - onderwerp:	verplicht	1 of meer	Dit is vooral handig als je op basis van datum en tijdstip bestanden een juist onderwerpsnaam wilt geven.
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

our $VERSION = '1.0';

use Image::ExifTool ':Public';
use Time::localtime;
use constant { true => 1, false => 0 };
use constant { ERROR => 2, WARNING => 1, DEBUG => 0};

my $default_filter = "*.JPG";

# filter		searching for 
# numbering		starts numbering from
# positions		number of positions the number after the date should look like
# subchar		character which should be added after the the prefix if a file of this name already exists
# prefix		instead of datetime as prefix another fixed prefix can be choosen
# exif_title		exif-tag for retrieving the title
# exif_datetime		the datetime retrieved from the exif-info in the file(de datum wordt afgeleid uit de exif-info van het bestand)
# exif_datetimeformat	the datetime should apply this format
# exif_timezone		the timezone applied to the exif-datetime
# pattern		if the datetime can't be retrieve from the exif-info, it tries to retrieve if from the filename
# overwrite_prefix	if yes, than take the prefix instead
#

my @Errorlines;

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	@Errorlines = ();
}

sub getfiles {
	my $self = shift;
	my @files = ();
	if (defined $self->filter()) {
		$self->setdebug($self->filter(), "getfiles:filter", $self->folder() . $self->filter());
		if ($self->folder_contains_spaces()) {
			@files = glob("\"" . $self->folder() . $self->filter() . "\"");
		} else {
			@files = glob($self->folder() . $self->filter());
		}
		$self->setdebug($self->filter(), "getfiles:filter", "number of files: " . scalar(@files));
		foreach my $file (sort @files) {
			$self->setdebug($file, "getfiles", "filter");
		}

	}
	return (sort @files);
}

sub filter {
	my $self = shift;
	return $self->{filter} || $default_filter;
}

sub folder {
	my $self = shift;
	my $folder = "";
	if (defined $self->{folder}) {
		$folder = $self->{folder};
		if (substr($folder, -1) ne "/") {
			$folder = $folder . "/";
		}
	}
	return $folder;
}

sub folder_contains_spaces {
	my $self = shift;
	my $contains = false;
	if ($self->folder() =~ /\s/) {
		$contains = true;
	}
	return $contains;
}

sub numbering {
	my $self = shift;
	return $self->{numbering};
}

sub counter {
	my $self = shift;
	my $counter = 1;
	if ($self->numbering =~ /^\d+$/) {
		$counter = $self->{numbering};
	}
	return $counter;
}

sub iscounter {
	my $self = shift;
	my $iscounter = false;
	if ($self->numbering =~ /^\d+$/) {
		$iscounter = true;
	}
	return $iscounter;
}

sub positions {
	my $self = shift;
	return $self->{positions};
}

sub subchar {
	my $self = shift;
	return $self->{subchar};
}

sub prefix {
	my $self = shift;
	return $self->{prefix};
}

sub exif_title {
	my $self = shift;
	return $self->{exif_title};
}

sub exif_datetime {
	my $self = shift;
	return $self->{exif_datetime};
}

sub exif_datetimeformat {
	my $self = shift;
	return $self->{exif_datetimeformat};
}
sub exif_timezone {
 	my $self = shift;
 	return $self->{exif_timezone};
}
 
sub exif_timezoneformat {
	my $self = shift;
	return $self->{exif_timezoneformat};
}
 
sub pattern {
	my $self = shift;
	return $self->{pattern};
} 

sub overwrite_prefix {
 	my $self = shift;
 	return $self->{overwrite_prefix};
}

sub seterror {
	my $self = shift;
	my $file = shift || "";
	my $type = shift || DEBUG;
	my $message = shift || "";
	push @Errorlines, {"file" => $file, "errortype" => $type, "errormessage" => $message};
}

sub setdebug {
	my $self = shift;
	my $file = shift || "";
	my $method = shift || "";
	my $message = shift || "";
	push @Errorlines, {"file" => $file, "errortype" => DEBUG, "errormessage" => "$method\t$message"};
}

sub errors {
	shift;
	return @Errorlines;
}

sub printerrors {
	my $self = shift;
	my $type = shift;
	my $text = "";
	my $errortype = "";
	foreach my $errorline (@Errorlines) {
		if ($errorline->{errortype} == DEBUG) {
			$errortype = "DEBUG";
		} elsif ($errorline->{errortype} == WARNING) {
			$errortype = "WARNING";
		} else {
			$errortype = "ERROR";
		}
		if ($errorline->{errortype} >= $type) {
			$text = $text . sprintf("%-30s %-10s %-100s\n", $errorline->{file}, $errortype, $errorline->{errormessage});
		}
	}
	return $text;
}

sub printall {
	my $self = shift;
	my $text = sprintf("%-20s %-20s\n", "Filter", $self->filter());
	my @files = $self->getfiles();
	$text = $text . sprintf("%-20s %d\n", "Count", scalar(@files));
	foreach my $file (@files) {
		$text = $text . sprintf("%-20s %-50s\n", "", $file);
	}
	if (defined $self->numbering()) {
		$text = $text . sprintf("%-20s %-50s\n", "Numbering", $self->numbering());
	}
	return $text;
}


1;
