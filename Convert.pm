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
use RenameFiles::RenameFile;

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
}

sub filter {
	my $self = shift;
	my $filter = shift;
	my $teller = $self->nummering();
	my $newfile;
	if (defined $filter) {
		$self->setdebug($filter, "Bestand:filter", $self->{map} . $filter);
#		my @files = glob("\"" . $self->{map} . $filter. "\"");
#		my @files = glob("\"" . $filter. "\"");
		my @files = glob($filter);
		$self->setdebug($filter, "Bestand:filter", "aantal bestanden: " . scalar(@files));
		foreach my $file (sort @files) {
			# initieel meegeven: bestand, exifdatum, exifdatumformaat, datumpatroon, exiftitel
			if ($self->isnummeringdatum) {
				$newfile = RenameFiles::EenBestand->new("bestand" => $file, "exifdatum" => $self->{exifdatum}, "exifdatumformaat" => $self->{exifdatumformaat},
					"datumpatroon" => $self->{patroon}, "exiftitel" => $self->{exiftitel}, "voorloop" => $self->{voorloop}, 
					"overschrijfvoorloop" => $self->{overschrijfvoorloop}, "exiftimezone" => $self->{exiftimezone});
			} else {
				$newfile = RenameFiles::EenBestand->new("bestand" => $file, "exifdatum" => $self->{exifdatum}, "exifdatumformaat" => $self->{exifdatumformaat},
					"datumpatroon" => $self->{patroon}, "exiftitel" => $self->{exiftitel}, "teller" => $teller, "posities" => $self->{posities},
					"voorloop" => $self->{voorloop}, "overschrijfvoorloop" => $self->{overschrijfvoorloop}, "exiftimezone" => $self->{exiftimezone});
			}
			$self->setdebug($newfile->bestand(), "Bestand:filter", "datum: " . $newfile->datumstring() . ", exif-datum: " . $self->{exifdatum});
			push (@Bestanden, $newfile);
			$teller++;
		}
	}
}



sub nummering {
	my $self = shift;
	my $mynummering = $self->{nummering} || 1;
	if ($mynummering =~ /^\d+$/) {
		$mynummering = $self->{nummering}
	} else {
		$mynummering = 1;
	}
	return $mynummering;
}

sub isnummeringdatum {
	my $self = shift;
	my $nummering = $self->{nummering} || 1;
	return ($nummering eq "T");
}

sub debug {
	my $self = shift;
	my $debug = 0;
	if (defined $self->{debug}) {
		if ($self->{debug} == 1) {
			$debug = 1;
		}
	}
	return $debug;
}


sub printexiftags {
	my $self = shift;
	my $bestand = shift;
	my $group = '';
	my $tag;
	my $errormessage = "";
	my $exiftool = new Image::ExifTool;
	my $info = $exiftool->ImageInfo($bestand, 'FileAccessDate');
	foreach $tag ($exiftool->GetFoundTags('Group0')) {
		if ($tag =~ /Date/) {
			if ($group ne $exiftool->GetGroup($tag)) {
				$group = $exiftool->GetGroup($tag);
				$errormessage .= "---- $group ----\n";
			}
			my $val = $info->{$tag};
			if (ref $val eq 'SCALAR') {
				if ($$val =~ /^Binary data/) {
					$val = "($$val)";
				} else {
					my $len = length($$val);
					$val = "(Binary data $len bytes)";
				}
			}
			$errormessage .= "$tag = $val\n";
		}
	}
	$self->setdebug($bestand, "Bestand:printexiftags", $errormessage);
}
	

sub printall {
# bestand
# extensie		( extensie afgeleid uit de bestandsnaam)
# datum			( datum/default uit de exif-info)
# voorloopstring	( datum+tijd, datum + nummer of defaultwaarde + nummer }
# subnummer		( gelijk aan sub )

	my $self = shift;
	my $tekst = "";
	foreach my $myfile (@Bestanden) {
		$tekst = $tekst . $myfile->print();
		$tekst = $tekst .  "-------------------------------------------\n";
	}
	return $tekst;
}

# public
# geef de te hernoemen bestanden, zet hernoem op 1, vul de omschrijving, pas eventueel de datum en bijhorende voorloopstring aan
sub geefbestanden {
	my $self = shift;
	my $tijdstart = shift;
	my $tijdeinde = shift;
	my $titel = shift;
	my $overschrijf = shift;
	my $datumshift = shift;
	my $tijdformat = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d %H:%M:%S");
	my $datumformat = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d");
	my $tijd_start;
	my $tijd_einde;
	if (defined $tijdstart) {
		$tijd_start = $tijdformat->parse_datetime($tijdstart);
		if (!($tijd_start)) {
			$tijd_start = $datumformat->parse_datetime($tijdstart);
		}
	}
	if (defined $tijdeinde) {
		$tijd_einde = $tijdformat->parse_datetime($tijdeinde);
		if (!($tijd_einde)) {
			$tijd_einde = $datumformat->parse_datetime($tijdeinde);
		}
	}
	my @hernoembestanden;
	foreach my $myfile (@Bestanden) {
	# bepaal of omschrjving uit titel komt of uit de exif-info per bestand
		$myfile->settitel_onderwerp($titel, $overschrijf);
		$myfile->setdatumshift_onderwerp($datumshift);
		if (! defined $overschrijf) {
			$overschrijf = "";
		}
		$self->setdebug($myfile->bestand(), "Bestand:geefbestanden", "voorloopstring: " . $myfile->voorloopstring() . ", titel: " . $myfile->titel() . 
			", exif-titel: " . $myfile->exiftitel() . ", overschrijf: $overschrijf, datum: " . $myfile->datumstring() . ", tijd-start: $tijdstart, tijd-einde: $tijdeinde");

	# bepaal of tijdverschuiving van toepassing is per bestand
	# bepaal of datum van bestand voldoet aan criteria
		if ($myfile->isgefilterd($tijd_start, $tijd_einde)) {
			push @hernoembestanden, $myfile;
		}
	}
	return @hernoembestanden;
}
	
sub clearall {
	@Bestanden = ();
}

sub seterror {
	my $self = shift;
	my $file = shift || "";
	my $type = shift || "";
	my $message = shift || "";
	push @Errorlines, {"file" => $file, "errortype" => $type, "errormessage" => $message};
}

sub setdebug {
	my $self = shift;
	my $file = shift || "";
	my $method = shift || "";
	my $message = shift || "";
	push @Errorlines, {"file" => $file, "errortype" => "debug", "errormessage" => "$method\t$message"};
}

sub printerrorfile {
	my $self = shift;
	my $data = shift;
	my $vandaagstring = shift;
	if ((defined $data) && (defined $vandaagstring)) {
		foreach my $errorline (@Errorlines) {
			if ($errorline->{errortype} eq "debug") {
				if ($self->debug() == 1) {
					print $data "DEBUG ($vandaagstring) " . $errorline->{file} . "\t=> " . $errorline->{errormessage} . "\n";
				}
			} else {
				print $data "($vandaagstring) " . $errorline->{file} . "\t=> " . $errorline->{errormessage} . "\n";
			}
		}
		foreach my $bestand (@Bestanden) {
			if (($bestand->{hernoem} == 0) && (defined $bestand->{datum})) {
				my $datestring = sprintf("%04s%02s%02s-%02s%02s%02s", $bestand->{datum}->year(), $bestand->{datum}->month(), $bestand->{datum}->day(), 
					$bestand->{datum}->hour(), $bestand->{datum}->minute(), $bestand->{datum}->second());
				print $data "($vandaagstring) " . $bestand->{bestand} . " ($datestring)\t=> niet hernoemd\n";
			}
			if (($bestand->{schrijfexif} != 1) && ($bestand->{hernoem} == 1)) {
				print $data "($vandaagstring) " . $bestand->{bestand} . " Geen exif-waardes geschreven\n";
			}
				
		}
	}
}

1;
