package My::Onderwerp;

#----------------------------------------- Onderwerp --------------------------------------------------------------------------------
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
#----------------------------------------- Onderwerp --------------------------------------------------------------------------------


# use module
use strict;
use warnings;
# use Image::ExifTool ':Public';
# use Time::localtime;

our $VERSION = '1.0';

# use Exporter qw(import);

# our @EXPORT_OK = qw(titel value_for_alias value_for_titel printall);

# lege waarde
my $leeg = "[leeg]";


sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->clear();
	return $self;
}

sub exif_titel {
	my $self = shift;
	return $self->{"exif-titel"};
}

sub print_exif_titel {
	my $self = shift;
	return $self->{"exif-titel"} || "";
}

sub overschrijf_titel {
	my $self = shift;
	return $self->{"overschrijf-titel"} || "nee";
}


sub tijd_start {
	my $self = shift;
	return $self->{"tijd-start"};
}

sub print_tijd_start {
	my $self = shift;
	return $self->{"tijd-start"} || "";
}

sub tijd_einde {
	my $self = shift;
	return $self->{"tijd-einde"};
}

sub print_tijd_einde {
	my $self = shift;
	return $self->{"tijd-einde"} || "";
}

sub datumshift {
	my $self = shift;
	return $self->{"datumshift"};
}

sub print_datumshift {
	my $self = shift;
	return $self->{"datumshift"} || "";
}

sub titel {
	my $self = shift;
	return $self->{"titel"};
}

sub print_titel {
	my $self = shift;
	return $self->{"titel"} || "";
}

sub clear {
	my $self = shift;
	$self->{"exif-titel"} = undef;
	$self->{"overschrijf-titel"} = "nee";
	$self->{"tijd-start"} = undef;
	$self->{"tijd-einde"} = undef;
	$self->{"datumshift"} = undef;
	$self->{"titel"} = undef;
}


sub print {
	my $self = shift;
	my $tekst = "";
	$tekst = $tekst . "exif-titel\t" . $self->print_exif_titel() . "\n";
	$tekst = $tekst . "overschrijf-titel\t" . $self->overschrijf_titel() . "\n";
	$tekst = $tekst . "tijd-start\t" . $self->print_tijd_start() . "\n";
	$tekst = $tekst . "tijd-einde\t" . $self->print_tijd_einde() . "\n";
	$tekst = $tekst . "datumshift\t" . $self->print_datumshift() . "\n";
	$tekst = $tekst . "titel\t" . $self->print_titel() . "\n";
	$tekst = $tekst . "------------------------------------------------------------------------------\n";
	return $tekst;
}


1;