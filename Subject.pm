package RenameFiles::Subject;

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
#              	- exif-title: 						het is mogelijk om het onderwerp uit de exif-informatie te halen. Hier geef je aan welke
#									exif-waarde je daarvoor wilt gebruiken. Mocht deze waarde niet gevuld zijn, dan wordt de 
#									waarde het attribuut titel gebruikt
# - subject:	verplicht	1 of meer	Dit is vooral handig als je op basis van datum en tijdstip bestanden een juist onderwerpsnaam wilt geven.
#              	- overwrite-title: 			nee			mocht je altijd de waarde van het attribuut titel willen gebruiken, dan geef je dit attribuut 
#									de waarde ja
#              	- datetime-start:  						per onderwerp regel kun je aangeven wat het start tijdstip is en het eindtijdstip, dit geef 
#									je aan in het formaat yyyy-mm-dd hh:MM:ss, de uren, minuten en seconden kun je weglaten.
#                             						de datum die hiervoor gebruikt wordt, heb je hiervoor bepaald en is de datum , die uiteindelijk 
#                             						gebruik wordt om het bestand te hernoemen.
#              	- datetime-end:  						werkt hetzelfde als tijdstart, maar geeft het eindtijdstip aan. Je kunt alleen een tijdstart 
#									opgeven zonder tijdeinde en omgekeerd.
#		- timeshift:						hiermee kun je de datum corrigeren in uren, minuten en seconden voor- of achteruit
#		- title:						de naam van het onderwerp indien deze niet uit de exif-informatie komt
#
# Mocht er iets fout gaan, dan wordt dit weggeschreven in het bestand fouten.txt in dezelfde map als de bestanden.
# Er wordt ook bijgehouden of alle bestanden zoals je die in de zoekopdracht hebt meegegeven wel hernoemd zijn. Als er een bestand
# niet hernoemd is, dan wordt dit in het foutenbestand opgenomen.
# Het kan ook zijn, dat de exif-waarde niet is gevonden, dan wordt geprobeerd om in het foutenbestand alle mogelijk exif-labels en
# waardes weer te geven.
#
# ------------------------------------------------------------------------------------------------------------------------------------#
		# <subject overwrite-title="yes" datetime-start="2018-09-06 14:00:00" datetime-end="2018-09-06 23:55:00" title="Javornik">
		# <subject overwrite-title="yes" timeshift="02:00:00" datetime-start="2018-04-23 14:00:00" datetime-end="2018-04-24 23:30:00" title="Tel Aviv - Yafo">
		# <subject overwrite-title="yes" datetime-start="2018-04-25 12:00:00" datetime-end="2018-04-25 14:40:00" title="Caesarea">


# use module
use strict;
use warnings;

our $VERSION = '1.0';

use Image::ExifTool ':Public';
use Time::localtime;
use DateTime::Format::Strptime;
use constant { true => 1, false => 0 };

my @Errorlines;
# initieel meegeven: 
#	overwrite_title
#	title
#	datetime_start
#	datetime_end
#	timeshift

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	$self->{datetime_error} = false;
# shifting is + or - for timeshift
	@Errorlines = ();
	$self->{shifting} = 1;
}

sub seterror {
	my $self = shift;
	my $type = shift || "";
	my $message = shift || "";
	push (@Errorlines, {"file" => "subject", "errortype" => $type, "errormessage" => $message});
}



sub overwrite_title {
	my $self = shift;
	my $overwrite = false;
	if (defined $self->{overwrite_title}) {
		if ($self->{overwrite_title} eq "yes") {
			$overwrite = true;
		}
	}
	return ($overwrite eq true);
}

sub title {
	my $self = shift;
	my $title = shift;
	if ($self->overwrite_title()) {
		if (defined $self->{title}) {
			$title = $self->{title}
		}
	}
	return $title;
}

sub datetime_start {
	my $self = shift;
	my $datetime_start = undef;
# check if datetime_start is set
	if (defined $self->{datetime_start}) {
# check if datetime_start has proper format
		if ($self->{datetime_start} =~ m/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d %H:%M:%S");
			$datetime_start = $format->parse_datetime($self->{datetime_start});
			if (!($datetime_start)) {
				$self->seterror("warning", sprintf("datetime-start %s is not correct", $self->{datetime_start}));
				$self->{datetime_error} = true;
			}
		} elsif ($self->{datetime_start} =~ m/\d{4}-\d{2}-\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d");
			$datetime_start = $format->parse_datetime($self->{datetime_start});
			if (!($datetime_start)) {
				$self->seterror("warning", sprintf("datetime-start %s is not correct", $self->{datetime_start}));
				$self->{datetime_error} = true;
			}
		} else {
			$self->seterror("warning", sprintf("datetime-start %s has not a proper format", $self->{datetime_start}));
			$self->{datetime_error} = true;
		}
	}
	return $datetime_start;
}

sub datetime_end {
	my $self = shift;
	my $datetime_end = undef;
# check if datetime_end is set
	if ((defined $self->{datetime_end}) && ($self->{datetime_error} eq false)) {
# check if datetime_end has proper format
		if ($self->{datetime_end} =~ m/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d %H:%M:%S");
			$datetime_end = $format->parse_datetime($self->{datetime_end});
		} elsif ($self->{datetime_end} =~ m/\d{4}-\d{2}-\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%Y-%m-%d");
			$datetime_end = $format->parse_datetime($self->{datetime_end});
		} else {
			$self->seterror("warning", sprintf("datetime-end %s has not a proper format", $self->{datetime_end}));
			$self->{datetime_error} = true;
		}
# check if datetime_end after datetime_start
		if (($datetime_end) && ($self->{datetime_error} eq false)) {
			my $datetime_start = $self->datetime_start();
			if (defined $datetime_start) {
				if ($datetime_end <= $datetime_start) {
					$self->seterror("warning", sprintf("datetime-end %s is before datime-start %04s-%02s-%02s %02s:%02s:%02s", 
						$self->{datetime_end}, 
						$datetime_start->year(), $datetime_start->month(), $datetime_start->day(),
						$datetime_start->hour(), $datetime_start->minute(), $datetime_start->second()));
					$self->{datimetime_error} = true;
				}
			}
		} else {
			$self->seterror("warning", sprintf("datetime-end %s is not correct", $self->{datetime_end}));
			$self->{datetime_error} = true;
		}
	}
	return $datetime_end;
}

sub timeshift {
	my $self = shift;
	my $timeshift = undef;
# check if timeshift is set
	if (defined $self->{timeshift}) {
# extract minus sign if applicable
		my $tempvalue = $self->{timeshift};
		if (substr($self->{timeshift}, 0, 1) eq "-") {
			$tempvalue = substr($self->value(), 1, length($self->{timeshift})-1);
			$self->{shifting} = -1;
		}
# check if datetime_end has proper format
		if ($tempvalue =~ m/\d{2}:\d{2}:\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%H:%M:%S");
			$timeshift = $format->parse_datetime($tempvalue);
			if (!($timeshift)) {
				$self->seterror("warning", sprintf("timeshift %s is not correct", $self->{timeshift}));
				$self->{datetime_error} = true;
			}
		} else {
			$self->seterror("warning", sprintf("timeshift %s has not a proper format", $self->{timeshift}));
			$self->{datetime_error} = true;
		}
	}
	return $timeshift;
}

sub datetime_error {
	my $self = shift;
	return $self->{datetime_error}
}

sub is_file_within_dateperiod {
	my $self = shift;
	my $filedatetime = shift;
	my $timezone = shift;
	my $value = false;
# shift start datetime en end datetime with timezone and timeshift
	if ($self->{datetime_error} eq false) {
		my $datetime_start = $self->datetime_start();
		$filedatetime = $filedatetime + $timezone + $self->{shifting} * $self->timeshift();
		if (defined $datetime_start) {
			if ($filedatetime >= $datetime_start) {
				$value = true;
			}
		} else {
			$value = true;
		}
		my $datetime_end = $self->datetime_end();
		if (($value eq true) && (defined $datetime_end)) {
			if ($filedatetime >= $datetime_end) {
				$value = false;
			}
		}
	} else {
		$value = false;
	}
	return $value;
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

# public
sub printerrors {
	my $self = shift;
	my $tekst = "\n";
	foreach my $errorline (@Errorlines) {
		$tekst = $tekst . sprintf("%-10s %-100s\n", $errorline->{errortype}, $errorline->{errormessage});
	}
	return $tekst;
}

sub printall {
	my $self = shift;
#	overwrite_title
#	title
#	datetime_start
#	datetime_end
#	timeshift
	my $tekst = sprintf("%-20s %-50s\n", "overwrite-title", $self->printboolean($self->overwrite_title()));
	$tekst = $tekst . sprintf("%-20s %-50s\n", "title", $self->title("Dummy title"));
	if ($self->datetime_error() eq false) {
		my $datetime_start = $self->datetime_start();
		if (defined $datetime_start) {
			$tekst = $tekst . sprintf("%-20s %04s-%02s-%02s %02s:%02s:%02s\n", "datetime-start", $datetime_start->year(), $datetime_start->month(),
				$datetime_start->day(), $datetime_start->hour(), $datetime_start->minute(), $datetime_start->second());
		}
		my $datetime_end = $self->datetime_end();
		if (defined $datetime_end) {
			$tekst = $tekst . sprintf("%-20s %04s-%02s-%02s %02s:%02s:%02s\n", "datetime-end", $datetime_end->year(), $datetime_end->month(),
				$datetime_end->day(), $datetime_end->hour(), $datetime_end->minute(), $datetime_end->second());
		}
		my $timeshift = $self->timeshift();
		if (defined $timeshift) {
			$tekst = $tekst . sprintf("%-20s %02s:%02s:%02s\n", "timeshift", $timeshift->hour(), $timeshift->minute(), $timeshift->second());
		}
	}
	$tekst = $tekst . $self->printerrors();
	return $tekst;
}

1;