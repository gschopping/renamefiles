package RenameFiles::RenameFile;

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
use constant { true => 1, false => 0 };
use constant { OK => 1, NoChanges => 2, WriteError = 0 };

# default values
my $default_extension = "JPG";
my $default_exif_datetime = "DateTimeOriginal";
my $default_exif_timezone = "TimeZone";
my $default_exif_datetimeformat = "%Y:%m:%d %H:%M:%S";
my $default_prefix = "Vandaag";
my $default_subchar = "a";
my $default_positions = 3;



# initieel meegeven: 
#	filename
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

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	$self->{renamed} = false;
	$self->{exif_written} = NoChanges;
	$self->{writeable} = false;
	$self->{exiftool} = new Image::ExifTool;
}

# public
sub initdatum {
	my $self = shift;
	if (defined $self->{filename}) {
		$self->{writeable} = $self->{exiftool}->CanWrite($self->extensie());
		my $info = $exiftool->ImageInfo($self->filename());
		my $parser = DateTime::Format::Strptime->new(pattern => $self->exif_datetimeformat());
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

sub extension {
	my $self = shift;
	my $extension = $default_extension;
	my @filenames = split /\./, $self->filename();
	if ($#filenames > 0) {
		$extension = $filenames[$#filenames];
	}
	return $extension;
}

sub filename_without_extension {
	my $self = shift;
	my $name = "";
	my @files = split /\./, $self->filename();  # foto.jpg
	$name = $files[0];
	for (my $i=1; $i < $#files; $i++) {
		$name = $name . "." . $files[$i];
	}
	return $name;
}

sub filename {
	my $self = shift;
	my $filename = "";
	if (defined $self->{filename}) {
		my @folders = split /\//, $self->{filename}; # D:/map/folder/foto.jpg
		$filename = $folders[$#folders];
	}
	return $filename;
}

sub folder {
	my $self = shift;
	my $folder = "";
	if (defined $self->{folder}) {
		$folder = $self->{folder};
		if (substr($folder, -1) ne "/") {
			$folder = $folder . "/";
		}
	} else {
		if (defined $self->{filename}) {
			my @folders = split /\//, $self->{filename}; # D:/map/folder/foto.jpg
			$folder = $folders[0];
			for (my $i=1; $i < $#folders; $i++) {
				$folder = $folder . "/" . $folders[$i];
			}
			$folder = $folder . "/";
		}
	}
	return $folder;
}

sub file_with_folder {
	my $self = shift;
#	return $self->map() . $self->bestand();
	return $self->filename();
}
	
sub exif_titlel {
	my $self = shift;
	return $self->{exif_title} || "";
}	

sub exif_datetime {
	my $self = shift;
	return $self->{exif_datetime} || $default_exif_datetime;
}

sub exif_datetimeformat {
	my $self = shift;
	return $self->{exif_datetimeformat} || $default_exif_datetimeformat;
}
		
sub exif_timezone {
	my $self = shift;
	return $self->{exif_timezone} || $default_exif_timezone;
}


sub datetime {
	my $self = shift;
	my $datetime = undef;
	if (defined $self->{datetime}) {
		$datetime = $self->{datetime}
	}
	return $datetime;
}

sub prefix {
	my $self = shift;
	return $self->{prefix} || $default_prefix;
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