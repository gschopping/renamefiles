package My::EenBestand;

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
#              	- overschrijf: 			nee			mocht je altijd de waarde van het attribuut titel willen gebruiken, dan geef je dit attribuut 
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

# use Exporter qw(import);

# our @EXPORT_OK = qw( voorloopstring  );



# lege waarde
# my $leeg = "[leeg]";
my $default_extensie = "JPG";
my $default_exifdatum = "DateTimeOriginal";
my $default_exifdatumformaat = "%Y:%m:%d %H:%M:%S";
my $default_datum = "Vandaag";
my $default_voorloop = "Vandaag";
# my $default_subwaarde = "a";
my $default_posities = 3;


# bestand
# extensie		( extensie afgeleid uit de bestandsnaam)
# datum			( datum uit de exif-info of uit bestandsformaat )
# exifdatumformaat	( uit Bestand, formaat om de datum uit de exif-tag te formateren }
# exifdatum		( uit Bestand, exif-tag om datum op te halen)
# voorloop		( voorloop uit convert of standaardwaarde als er geen voorloop is, maar ook geen datum opgehaald kan worden }
# teller		( oplopende teller )
# tellerposities	( altijd uitvullen op bv 3 cijfers )
# hernoem		( bestand gefilterd om te worden hernoemd )
# schrijfexif		( exif-tags zijn geschreven in bestand )
# datumshiftuitonderwerp	( datum uit onderwerp-tag 0 of 1 )
# datumshift_exif		( datumshift via een exif-tag )
# datumshift_onderwerp		{ datumshift via onderwerp }
# datumpatroon			{ datum uit bestandsnaam halen of aanmaak, op wijzig of opendatum bepalen )
# titeluitonderwerp		( titel uit onderwerp-tag 0 of 1 )
# overschrijftiteluitonderwerp	( de titel uit het onderwerp altijd gebruiken, ook als de bijbehorende exif-tag is gevonden )
# titel_exif			( titel uit exif-tag )
# titel_onderwerp		( titel uit onderwerp )
# exiftitel			( exif-tag om titel op te halen )
# kanschrijven			{ exiftool: CanWrite functie )

# initieel meegeven: 
#	bestand
#	exifdatum
#	exifdatumformaat
#	datumpatroon
#	exiftitel
#	subnummer
#	teller

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	$self->{hernoem} = 0;
	$self->{schrijfexif} = 2;
	$self->{datumshiftuitonderwerp} = 0;
	$self->{titeluitonderwerp} = 0;
	$self->{overschrijftiteluitonderwerp} = 0;
	$self->{overschrijfvoorloopuitconvert} = 0;
	$self->{kanschrijven} = 0;
	$self->initdatum();
	if (defined $self->{voorloop}) {
		$self->setvoorloop($self->{voorloop}, $self->{overschrijfvoorloop});
	}
}

# public
sub initdatum {
	my $self = shift;
	if (defined $self->{bestand}) {
		my $exiftool = new Image::ExifTool;
		$self->{kanschrijven} = $exiftool->CanWrite($self->extensie());
		my $info = $exiftool->ImageInfo($self->bestand());
		my $parser = DateTime::Format::Strptime->new(pattern => $self->exifdatumformaat());
		my $datum = $info->{$self->exifdatum()};
		if ($datum) {
			$self->setdatum($parser->parse_datetime($datum));
		} else {
			if (defined $self->{datumpatroon}) {
				my $fileparser = DateTime::Format::Strptime->new(pattern => $self->{datumpatroon});
				my $datestring;
			# indien patroon in naam bestand, haal dan de datum/tijd van het bestand op
				if ($self->{datumpatroon} eq "CreateDateTime") {
					$datestring = ctime(stat($self->bestand())->ctime);
					$self->setdatum($fileparser->parse_datetime($datestring));
				} elsif ($self->{datumpatroon} eq "ModifyDateTime") {
					$datestring = ctime(stat($self->bestand())->mtime);
					$self->setdatum($fileparser->parse_datetime($datestring));
				} elsif ($self->{datumpatroon} eq "AccessDateTime") {
					$datestring = ctime(stat($self->bestand())->atime);
					$self->setdatum($fileparser->parse_datetime($datestring));
				} else {
			# bepaal datumstring aan de hand van de bestandsnaam
					$self->setdatum($fileparser->parse_datetime($self->bestandsnaam()));
				}
			} else {
				# my $errormessage = "Kan de exif-tag " . $self->exif_datum() . " niet vinden, mogelijke tags:\n";
				# my $group = '';
				# my $tag;
				# foreach $tag ($exiftool->GetFoundTags('Group0')) {
				# # toon alleen de exif-tags met Date in de naam
					# if ($tag =~ /Date/) {
						# if ($group ne $exiftool->GetGroup($tag)) {
							# $group = $exiftool->GetGroup($tag);
							# $errormessage .= "---- $group ----\n";
						# }
						# my $val = $info->{$tag};
						# if (ref $val eq 'SCALAR') {
							# if ($$val =~ /^Binary data/) {
								# $val = "($$val)";
							# } else {
								# my $len = length($$val);
								# $val = "(Binary data $len bytes)";
							# }
						# }
						# $errormessage .= "$tag = $val\n";
					# }
				# }
				# $self->seterror($data, "exif", $errormessage);
			}
		 }
		if (defined $self->{exiftitel}) {
			$self->{titel_exif} = $info->{$self->{exiftitel}};
		}
	}

}	

sub extensie {
	my $self = shift;
	my $extensie = $default_extensie;
	my @bestand = split /\./, $self->bestand();
	if ($#bestand > 0) {
		$extensie = $bestand[$#bestand];
	}
	return $extensie;
}

sub bestandsnaam {
	my $self = shift;
	my $naam = "";
	my @bestand = split /\./, $self->bestand();  # foto.jpg
	$naam = $bestand[0];
	for (my $i=1; $i < $#bestand; $i++) {
		$naam = $naam . "." . $bestand[$i];
	}
	return $naam;
}

sub bestand {
	my $self = shift;
	my $bestand = "";
	if (defined $self->{bestand}) {
		my @maps = split /\//, $self->{bestand}; # D:/map/folder/foto.jpg
		$bestand = $maps[$#maps];
	}
	return $bestand;
}

sub map {
	my $self = shift;
	my $map = "";
	if (defined $self->{map}) {
		$map = $self->{map};
		if (substr($map, -1) ne "/") {
			$map = $map . "/";
		}
	} else {
		if (defined $self->{bestand}) {
			my @maps = split /\//, $self->{bestand}; # D:/map/folder/foto.jpg
			$map = $maps[0];
			for (my $i=1; $i < $#maps; $i++) {
				$map = $map . "/" . $maps[$i];
			}
			$map = $map . "/";
		}
	}
	return $map;
}

sub bestandplusmap {
	my $self = shift;
#	return $self->map() . $self->bestand();
	return $self->bestand();
}
	
sub exiftitel {
	my $self = shift;
	return $self->{exiftitel} || "";
}	

sub exifdatum {
	my $self = shift;
	return $self->{exifdatum} || $default_exifdatum;
}

sub exifdatumformaat {
	my $self = shift;
	return $self->{exifdatumformaat} || $default_exifdatumformaat;
}
		

sub datum {
	my $self = shift;
	my $parser = DateTime::Format::Strptime->new(pattern => $default_exifdatumformaat);
	return $self->{datum} || $parser->parse_datetime("1980:01:01 00:00:00");
}

sub datumstring {
	my $self = shift;
	my $datum = $self->datum();
	return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $datum->year(), $datum->mon(), $datum->mday(), $datum->hour(), $datum->min(), $datum->sec());
}

sub setdatum {
	my $self = shift;
	my $datum = shift;
	$self->{datum} = $datum;
}

sub isdatum {
	my $self = shift;
	my $isdatum = 0;
	if (defined $self->{datum}) {
		$isdatum = 1;
	}
	return $isdatum;
}

sub voorloop {
	my $self = shift;
	return $self->{voorloop} || "";
}

# public
sub setvoorloop {
	my $self = shift;
	my $voorloop = shift;
	my $overschrijf = shift;
	if (($voorloop) && (defined $overschrijf) && ($overschrijf eq "ja")) {
		$self->{overschrijfvoorloopuitconvert} = 1;
	}
	$self->{voorloop} = $voorloop || "";
}


sub isvoorloop {
	my $self = shift;
	my $isvoorloop = 0;
	if (defined $self->{voorloop}) {
		$isvoorloop = 1;
	}
	return $isvoorloop;
}

sub setteller {
	my $self = shift;
	my $teller = shift;
	$self->{teller} = $teller || 1;
}

sub isteller {
	my $self = shift;
	my $isteller = 0;
	if (defined $self->{teller}) {
		$isteller = 1;
	}
	return $isteller;
}

sub tellerformaat {
	my $self = shift;
	my $posities = $self->{tellerposities} || $default_posities;
	return "%0" . $posities . "d";
}
	
sub tellerstring {
	my $self = shift;
	my $str = "";
	if ($self->isteller()) {
		$str = sprintf($self->tellerformaat(), $self->{teller});
	}
	return $str;
}

sub settellerposities {
	my $self = shift;
	my $posities = shift;
	$self->{tellerposities} = $posities || $default_posities;
}

sub hernoem {
	my $self = shift;
	return $self->{hernoem} || 0;
}

sub sethernoem {
	my $self = shift;
	$self->{hernoem} = 1;
}

sub schrijfexif {
	my $self = shift;
	return $self->{schrijfexif} || 0;
}

# public
sub setschrijfexif {
	my $self = shift;
	my $schrijfexif = shift;
	$self->{schrijfexif} = $schrijfexif;
}

sub kanschrijven {
	my $self = shift;
	return ($self->{kanschrijven} == 1);
}

# public
sub setdatumshift_onderwerp {
	my $self = shift;
	my $datumshift = shift;
	if (defined $datumshift) {
		$self->{datumshift_onderwerp} = $datumshift;
		$self->{datumshiftuitonderwerp} = 1;
	} else {
		$self->{datumshiftuitonderwerp} = 0;
	}
}

sub setdatumshift_exif {
	my $self = shift;
	my $datumshift = shift;
	$self->{datumshift_exif} = $datumshift;
}

# public
sub settitel_onderwerp {
	my $self = shift;
	my $titel = shift;
	my $overschrijf = shift;
	$self->{titel_onderwerp} = $titel;
	if (defined $titel) {
		$self->{titeluitonderwerp} = 1;
	}
	if ((defined $titel) && (defined $overschrijf) && ($overschrijf eq "ja")) {
		$self->{overschrijftiteluitonderwerp} = 1;
	}
}

sub titel_onderwerp {
	my $self = shift;
	my $titel = "";
	if (defined $self->{titel_onderwerp}) {
		$titel = $self->{titel_onderwerp};
	}
	return $titel;
}

sub settitel_exif {
	my $self = shift;
	my $titel = shift;
	$self->{titel_exif} = $titel;
}

sub titel_exif {
	my $self = shift;
	my $titel = "";
	if (defined $self->{titel_exif}) {
		$titel = $self->{titel_exif};
	}
	return $titel;
}

# public
sub voorloopstring {
	my $self = shift;
	my $datestring = $self->voorloop() . $self->tellerstring();
	if ((! $self->isvoorloop()) && $self->isdatum() && (! $self->{overschrijfvoorloopuitconvert})) {
		my $datum = $self->datumshift();
		if ($self->isteller()) {
			$datestring = sprintf("%04s%02s%02s-", $datum->year(), $datum->month(), $datum->day()) . $self->tellerstring();
		} else {
			$datestring = sprintf("%04s%02s%02s-%02s%02s%02s", $datum->year(), $datum->month(), $datum->day(), $datum->hour(), $datum->minute(), $datum->second())
		}
	}
	return $datestring;
}

# public
sub titel {
	my $self = shift;
	my $titel = "";
	if (($self->{overschrijftiteluitonderwerp}) || ($self->{titeluitonderwerp} && (! defined $self->{titel_exif}))) {
		$titel = $self->titel_onderwerp();
	} else {
		$titel = $self->titel_exif();
	}
	return $titel;
}

sub datumshift {
	my $self = shift;
	my $datum = $self->datum();
	if ($self->{datumshiftuitonderwerp} && (defined $self->{datumshift_onderwerp}) && $self->isdatum()) {
		if (substr($self->{datumshift_onderwerp}, 0, 1) eq "-") {
			my $tempdatumshift = substr($self->{datumshift_onderwerp}, 1, length($self->{datumshift_onderwerp})-1);
			my $duration = DateTime::Format::Strptime->new(pattern => "%H:%M:%S");
			my $durationdatum = $duration->parse_datetime($tempdatumshift);
			$datum = $datum - DateTime::Duration->new(hours => $durationdatum->hour(), minutes => $durationdatum->minute(), seconds => $durationdatum->second());
		} else {
			my $duration = DateTime::Format::Strptime->new(pattern => "%H:%M:%S");
			my $durationdatum = $duration->parse_datetime($self->{datumshift_onderwerp});
			$datum = $datum + DateTime::Duration->new(hours => $durationdatum->hour(), minutes => $durationdatum->minute(), seconds => $durationdatum->second());
		}
	}
	return $datum;
}
		
# public
sub isgefilterd {
	my $self = shift;
	my $tijd_start = shift;
	my $tijd_einde = shift;
	my $gefilterd = 0;
	if (! $self->hernoem()) {
		if (defined $tijd_start) {
			if ($self->datum() >= $tijd_start) {
				if (defined $tijd_einde) {
					if ($self->datum() <= $tijd_einde) {
	# Datum bestand kleiner dan tijdeinde
						$gefilterd = 1;
						$self->sethernoem();
					}
				} else {
	# er is geen tijdeinde gedefinieerd
					$gefilterd = 1;
					$self->sethernoem();
				}
			}
		} else {
	# er is geen tijdstart gedeinieerd
			if (defined $tijd_einde) {
				if ($self->{datum} <= $tijd_einde) {
	# Datum bestand kleiner dan tijeinde
					$gefilterd = 1;
					$self->sethernoem();
				}
			} else {
	# er is geen tijdeinde gedefinieerd
				$gefilterd = 1;
				$self->sethernoem();
			}
		}
	}
	return $gefilterd;
}

# bestand
# extensie		( extensie afgeleid uit de bestandsnaam)
# datum			( datum uit de exif-info of uit bestandsformaat )
# exifdatumformaat	( uit Bestand, formaat om de datum uit de exif-tag te formateren }
# exifdatum		( uit Bestand, exif-tag om datum op te halen)
# voorloop		( voorloop uit convert of standaardwaarde als er geen voorloop is, maar ook geen datum opgehaald kan worden }
# subnummer		( gelijk aan subwaarde )
# teller		( oplopende teller )
# tellerposities	( altijd uitvullen op bv 3 cijfers )
# hernoem		( bestand gefilterd om te worden hernoemd )
# schrijfexif		( exif-tags zijn geschreven in bestand )
# datumshiftuitonderwerp	( datum uit onderwerp-tag 0 of 1 )
# datumshift_exif		( datumshift via een exif-tag )
# datumshift_onderwerp		{ datumshift via onderwerp }
# datumpatroon			{ datum uit bestandsnaam halen of aanmaak, op wijzig of opendatum bepalen )
# titeluitonderwerp		( titel uit onderwerp-tag 0 of 1 )
# overschrijftiteluitonderwerp	( de titel uit het onderwerp altijd gebruiken, ook als de bijbehorende exif-tag is gevonden )
# titel_exif			( titel uit exif-tag )
# titel_onderwerp		( titel uit onderwerp )
# exiftitel			( exif-tag om titel op te halen )
# kanschrijven			{ exiftool: CanWrite functie )

sub print {
	my $self = shift;
	my $tekst = "bestand:\t\t" . $self->bestand() . "\n";
	$tekst = $tekst . "map:\t\t\t" . $self->map() . "\n";
	$tekst = $tekst . "bestandsnaam:\t\t" . $self->bestandsnaam() . "\n";
	$tekst = $tekst . "extensie:\t\t" . $self->extensie() . "\n";
	$tekst = $tekst . "exifdatumformaat:\t" . $self->exifdatumformaat() . "\n";
	$tekst = $tekst . "exifdatum:\t\t" . $self->exifdatum() . "\n";
	$tekst = $tekst . "exiftitel:\t\t" . $self->titel_exif() . "\n";
	$tekst = $tekst . "datumpatroon:\t\t";
	if (defined $self->{datumpatroon}) {
		$tekst = $tekst . $self->{datumpatroon}
	}
	$tekst = $tekst . "\n";
	$tekst = $tekst . "overschrijf-voorloop:\t";
	if (defined $self->{overschrijfvoorloop}) {
		$tekst = $tekst . $self->{overschrijfvoorloop}
	}
	$tekst = $tekst . "\n";
	$tekst = $tekst . "voorloopstring:\t\t" . $self->voorloopstring() . "\n";
	$tekst = $tekst . "titel:\t\t\t";
	$tekst = $tekst . $self->titel_onderwerp();
	$tekst = $tekst . "\n";
	$tekst = $tekst . "datum:\t\t\t";
	if ($self->isdatum()) {
		$tekst = $tekst . sprintf("%04s-%02s-%02s %02s:%02s:%02s", $self->datum()->year(), $self->datum()->month(), $self->datum()->day(), 
			$self->datum()->hour(), $self->datum()->minute(), $self->datum()->second());
	}
	$tekst = $tekst . "\n";
	$tekst = $tekst . "Kan schrijven:\t\t";
	if ($self->{kanschrijven}) {
		$tekst = $tekst . "ja";
	} else {
		$tekst = $tekst . "nee";
	}
	$tekst = $tekst . "\n";
	$tekst = $tekst . "Schrijf Exif:\t\t" . $self->{schrijfexif} . "\n";
	my $nieuwbestand = $self->voorloopstring();
	if (($nieuwbestand ne "") && ($self->titel() ne "")) {
		$nieuwbestand = $nieuwbestand . " ";
	}
	$tekst = $tekst . "Nieuw bestand:\t\t" . $nieuwbestand . $self->titel() . "." . $self->extensie() . "\n";
	return $tekst;
}

1;