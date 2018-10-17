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
use DateTime::Format::Strptime;
use constant { true => 1, false => 0 };
use constant { OK => 1, NoChanges => 2, WriteError => 0 };

# default values
my $default_extension = "JPG";
my $default_exif_datetime = "DateTimeOriginal";
my $default_exif_timezone = "TimeZone";
my $default_exif_title = "Title";
my $default_exif_datetimeformat = "%Y:%m:%d %H:%M:%S";
my $default_prefix = "Vandaag";
my $default_subchar = "a";
my $default_positionsformat = "%03d";
my $default_numberingstring = "000";
my $default_pattern = "%Y%m%d_%H%M%S";

my $empty = "[empty]";


my @Errorlines;


# initieel meegeven: 
#	filename
# positions		number of positions the number after the date should look like
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
	$self->{writable} = false;
	$self->{norename} = true;
	$self->initdatum();
}

sub seterror {
	my $self = shift;
	my $type = shift || "";
	my $message = shift || "";
	push (@Errorlines, {"file" => $self->filename(), "errortype" => $type, "errormessage" => $message});
}

sub setdebug {
	my $self = shift;
	my $method = shift || "";
	my $message = shift || "";
	push @Errorlines, {"file" => $self->filename(), "errortype" => "debug", "errormessage" => "$method\t$message"};
}

	

# extract all kind of exif-data immediately after creating class
sub initdatum {
	my $self = shift;
	if (defined $self->{filename}) {
		my $exiftool = new Image::ExifTool;
		$self->{writable} = Image::ExifTool::CanWrite($self->extension());
		my $info = $exiftool->ImageInfo($self->filename_with_folder());
		my $parser = DateTime::Format::Strptime->new(pattern => $self->exif_datetimeformat());
		my $datetime = $info->{$self->exif_datetime()};
		if ($datetime) {
			$self->{datetime} = $parser->parse_datetime($datetime);
		} else {
			if (defined $self->{pattern}) {
				my $fileparser = DateTime::Format::Strptime->new(pattern => $self->pattern());
				my $datestring;
			# indien patroon in naam bestand, haal dan de datum/tijd van het bestand op
				if ($self->pattern() eq "CreateDateTime") {
					$datestring = ctime(stat($self->filename())->ctime);
					$self->{datetime} = $fileparser->parse_datetime($datestring);
				} elsif ($self->pattern() eq "ModifyDateTime") {
					$datestring = ctime(stat($self->filename())->mtime);
					$self->{datetime} = $fileparser->parse_datetime($datestring);
				} elsif ($self->pattern() eq "AccessDateTime") {
					$datestring = ctime(stat($self->filename())->atime);
					$self->{datetime} = $fileparser->parse_datetime($datestring);
				} else {
			# bepaal datumstring aan de hand van de bestandsnaam
					$self->{datetime} = $fileparser->parse_datetime($self->filename_without_extension());
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
		if (defined $self->{exif_title}) {
			$self->{title} = $info->{$self->{exif_title}};
		}
		if (defined $self->{exif_timezone}) {
			my $timezonestring = $info->{$self->{exif_timezone}};
			$parser = DateTime::Format::Strptime->new(pattern => "%H:%M");
			if (defined $timezonestring) {
				$self->{timezone} = $parser->parse_datetime($timezonestring);
			}
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

sub filename_with_folder {
	my $self = shift;
	return $self->folder() . $self->filename();
#	return $self->filename();
}
	
sub exif_title {
	my $self = shift;
	return $self->{exif_title} || $default_exif_title;
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

sub timezone {
	my $self = shift;
	my $timezone = undef;
	if (defined $self->{timezone}) {
		$timezone = $self->{timezone};
	}
	return $timezone;
}

sub pattern {
	my $self = shift;
	return $self->{pattern} || $default_pattern;
}

sub prefix {
	my $self = shift;
	return $self->{prefix} || $default_prefix;
}

sub overwrite_prefix {
	my $self = shift;
	return $self->{overwrite_prefix} || false;
}

sub positionsformat {
	my $self = shift;
	my $positionsformat = $default_positionsformat;
	if (defined $self->{positions}) {
		if ($self->{positions} =~ /^\d+$/) {
			$positionsformat = "%0" . $self->{positions} . "d";
		}
	}
	return $positionsformat;
}
	
	
sub title {
	my $self = shift;
	return $self->{title} || "";
}

sub writable {
	my $self = shift;
	return $self->{writable} || false;
}

sub prefix_string {
	my $self = shift;
	my $numbering = shift;
	my $prefix = "";
	my $numberingstring;
	if ($numbering =~ /^\d+$/) {
		$numberingstring = sprintf($self->positionsformat, $numbering);
	} elsif (defined $self->datetime()) {
		$numberingstring = sprintf("%02s%02s%02s", $self->datetime()->hour(), $self->datetime()->minute(), $self->datetime()->second());
	} else {
		$numberingstring = $default_numberingstring;
	}
	if ($self->overwrite_prefix()) {
		$prefix = $self->prefix();
	} elsif (defined $self->datetime()) {
		$prefix = sprintf("%04s%02s%02s", $self->datetime()->year(), $self->datetime()->month(), $self->datetime()->day());
	} else {
		$prefix = $self->prefix();
	}
	if ($numberingstring ne "") {
		$prefix = $prefix . "-" . $numberingstring;
	}
	return $prefix;
}

sub setrename {
	my $self = shift;
	my $value = shift;
	$self->{norename} = true;
	if (defined $value) {
		if ($value eq true) {
			$self->{norename} = false;
		}
	}
}

sub rename {
	my $self = shift;
	my $title = shift;
	my $numbering = shift;
	my $subchar = shift;
	my $newfile;
	my $space = "";
	my $prefix_string = $self->prefix_string($numbering);
	if (($prefix_string ne "") && ($title ne "")){
		$space = " ";
	}
	
	unless (-e $self->folder(). $prefix_string . $space . $title . "." . $self->extension()) {
		$newfile = $prefix_string . $space . $title . "." . $self->extension();
		print $self->filename() . " =>\t$newfile\n";
		$self->seterror($self->filename(), "rename", $newfile);
		$newfile = $self->folder() . $newfile;
		if ($self->{norename} eq false) {
			rename $self->filename_with_folder(), $newfile;
		}
	} else {
		while (-e $self->folder() . $prefix_string . $subchar . $space . $title . "." . $self->extension()) {
			$subchar = chr(1 + ord $subchar);
		}
		$newfile = $prefix_string . $subchar . $space . $title . "." . $self->extension();
		print $self->filename() . " =>\t$newfile\n";
		$self->seterror($self->filename(), "rename", $newfile);
		$newfile = $self->folder() . $newfile;
		if ($self->{norename} eq false) {
			my $success = rename $self->filename_with_folder(), $newfile;
			if ($success eq true) {
				$self->{filename} = $newfile;
			}
		}
	}
}

sub write_exiftags {
	my $self = shift;
	my $aliases = shift;
	if (defined $aliases) {
		my $exiftool = new Image::ExifTool;

	# wijzig de exif-attributen in het bestand
		my $write_exif = false;
		$exiftool->SaveNewValues();
		my $success = false;
		foreach my $alias @{$aliases} {
			if ($alias->value_or_default() ne $empty) {
				if ($alias->type() eq "datetime") {
					$success = $exiftool->SetNewValue($alias->titel() => $alias->absvalue_or_default(), Shift => $alias->dateshift());
					$self->setdebug("Exiftool:SetNewValue", $alias->title() . ", " . $alias->value_or_default() . ", " . $alias->dateshift());
				} else {
					$success = $exiftool->SetNewValue($alias->title() => $alias->value_or_default());
					$self->setdebug("Exiftool:SetNewValue", $alias->title() . ", " . $alias->value_or_default());
				}
				if ($success eq false) {
					$self->seterror("exif", sprintf("Can not write tag %s with value %s", $alias->title(), $alias->value_or_default());
				} else {
					$write_exif = true;
					$alias->written();
				}
	# vul de exif-waardes in als de exif-tag overeenkomt met de definitie in convert
				if ($alias->isexif_title($self->exif_title())) {
					$self->{title} = $alias->value_or_default());
				}
	# ================== hier verder kijken
				if ($alias->isexif_date($exif_datetime)) {
					$self->{datetimesetdatumshift_exif($exifvalue->waarde());
				}

			}
		}
		if (($write_exif eq true) && ($self->{norename} eq false)) {
			$success = $exiftool->WriteInfo($self->filename());
			$self->{exif_written} = $success;
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
}


sub printboolean {
	shift;
	my $boolean = shift;
	my $value = "no";
	if ($boolean eq true) {
		$value = "yes";
	}
	return $value;
}

sub printwritten {
	shift
	my $written = shift;
	my $value = "NoChanges";
	if ($written eq OK) {
		$value = "OK"
	} elsif ($written eq WriteError) {
		$value = "WriteError";
	}
	return $value;
}
	

sub print {
	my $self = shift;
	my $tekst = sprintf("%-20s %-50s\n", "filename", $self->filename());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "folder", $self->folder());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "extension", $self->extension());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "exif-datetimeformat", $self->exif_datetimeformat());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "exif-datetime", $self->exif_datetime());
	if (defined $self->datetime()) {
		$tekst = $tekst . sprintf("%-20s %04s-%02s-%02s %02s:%02s:%02s\n", "datetime", $self->datetime()->year(), $self->datetime()->month(),
			$self->datetime()->day(), $self->datetime()->hour(), $self->datetime()->minute(), $self->datetime()->second());
	}
	if (defined $self->timezone()) {
		$tekst = $tekst . sprintf("%-20s %02s:%02s:%02s\n", "timezone", $self->timezone()->hour(), $self->timezone()->minute(), $self->timezone()->second());
	}
	$tekst = $tekst . sprintf("%-20s %-50s\n", "positions", $self->positionsformat());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "prefix", $self->prefix());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "overwrite-prefix", $self->printboolean($self->overwrite_prefix()));
	$tekst = $tekst . sprintf("%-20s %-50s\n", "writable", $self->printboolean($self->writable()));
	$tekst = $tekst . sprintf("%-20s %-50s\n", "exif-title", $self->exif_title());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "title", $self->title());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "pattern", $self->pattern());
	$tekst = $tekst . sprintf("%-20s %-50s\n", "exif-written", $self->printwritten($self->{exif_written}));
	return $tekst;
}

1;