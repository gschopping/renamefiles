package My::Alias;

#----------------------------------------- Alias --------------------------------------------------------------------------------
# - alias:			0 of meer	er kunnen meerdere alias-tags worden aangemaakt
#		- titel:	verplicht		naam van de exif-tag
#		- default:				de standaardwaarde indien exif onder ondewerp niet voorkomt of niet is gevuld met een waarde
#		- type:					als deze datum is dan wordt de datum met deze waarde opgeteld of afgetrokken
#		- content:	verplicht		de alias zelf, deze mag vaker voorkomen
#----------------------------------------- Alias --------------------------------------------------------------------------------


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
# my $default_extensie = "JPG";
# my $default_exifdatum = "DateTimeOriginal";
# my $default_exifdatumformaat = "%Y:%m:%d %H:%M:%S";
# my $default_datum = "Vandaag";
# my $default_voorloop = "Vandaag";
# my $default_subwaarde = "a";
# my $default_posities = 3;

# titel
# default
# alias
# type
# value
# geschreven (standaard false) naar true indien daadwerkelijk deze tag in het bestand is geschreven
# exif_titel (standaard false) naar true indien de exif-titel in onderwerp overeenkomt met deze
# exif_datum (standaard false) naar true indien de exif-datum in onderwerp overeenkomt met deze

my @Aliases;

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->{geschreven} = 0;
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	push @Aliases, $self;
}

sub titel {
	my $self = shift;
	return $self->{titel} || $leeg;
}

sub titel_titel {
	my $self = shift;
	my $titel_titel = $self->titel();
	my @titels = split /\:/, $self->titel();
	if ($#titels > 0) {
		$titel_titel = $titels[1];
	}
	return $titel_titel;
}

sub titel_groep {
	my $self = shift;
	my $titel_groep = "";
	my @titels = split /\:/, $self->titel();
	if ($#titels > 0) {
		$titel_groep = $titels[0];
	}
	return $titel_groep;
}
	

sub default {
	my $self = shift;
	return $self->{default} || $leeg;
}

sub alias {
	my $self = shift;
	return $self->{alias} || $leeg;
}

sub type {
	my $self = shift;
	return $self->{type} || $leeg;
}

sub value {
	my $self = shift;
	return $self->{value} || $leeg;
}

sub geschreven {
	my $self = shift;
	$self->{geschreven} = 1;
}

sub nietgeschreven {
	my $self = shift;
	$self->{geschreven} = 0;
}

sub isgeschreven {
	my $self = shift;
	return ($self->{geschreven} == 1);
}

sub isexif_titel {
	my $self = shift;
	my $exif_titel = shift;
	my $found = 0;
	if (defined $exif_titel) {
		if ($exif_titel eq $self->titel_titel()) {
			$found = 1;
		}
	}
	return ($found == 1);
}

sub isexif_datum {
	my $self = shift;
	my $exif_datum = shift;
	my $found = 0;
	if (defined $exif_datum) {
		if ($exif_datum eq $self->titel_titel()) {
			$found = 1;
		}
	}
	return $found == 1;
}

sub clear {
	my $self = shift;
	$self->{value} = $leeg;
}

sub clearall {
	foreach my $myalias (@Aliases) {
		$myalias->clear();
	}
}

sub value_for_alias {
	shift;
	my $data1 = shift || $leeg;
	my $data2 = shift || $leeg;
	my $found = 0;
	foreach my $myalias (@Aliases) {
		if ($myalias->{alias} eq $data1) {
			$myalias->{value} = $data2;
			$found = 1;
		}
	}
	return $found;
}

sub value_for_titel {
	shift;
	my $data1 = shift || $leeg;
	my $data2 = shift || $leeg;
	my $found = 0;
	foreach my $myalias (@Aliases) {
		if ($myalias->{titel} eq $data1) {
			$myalias->{value} = $data2;
			$found = 1;
		}
	}
	return $found;
}

sub waarde {
	my $self = shift;
	my $waarde = $leeg;
	if (($self->value() ne $leeg) || ($self->default() ne $leeg)) {
		if ($self->value() ne $leeg) {
			$waarde = $self->value()
		} else {
			$waarde = $self->default()
		}
	}
	return $waarde;
}

sub abswaarde {
	my $self = shift;
	my $waarde = $leeg;
	if (($self->value() ne $leeg) || ($self->default() ne $leeg)) {
		if ($self->value() ne $leeg) {
			$waarde = $self->value()
		} else {
			$waarde = $self->default()
		}
		if ($self->type() eq "datum") {
			if (substr($self->value(), 0, 1) eq "-") {
				$waarde = substr($self->value(), 1, length($self->value())-1);
			} else {
				$waarde = $self->value();
			}
		}
	}
	return $waarde;
}

sub datumshift {
	my $self = shift;
	my $shift = 0;
	if (($self->value() ne $leeg) || ($self->default() ne $leeg)) {
		if ($self->type() eq "datum") {
			if (substr($self->value(), 0, 1) eq "-") {
				$shift = -1;
			} else {
				$shift = 1;
			}
		}
	}
	return $shift;
}

sub printall {
	my $tekst = "";
	foreach my $myalias (@Aliases) {
		$tekst = $tekst . "titel\t" . $myalias->titel() . "\n";
		$tekst = $tekst .  "default\t" . $myalias->default() . "\n";
		$tekst = $tekst .  "alias\t" . $myalias->alias() . "\n";
		$tekst = $tekst .  "value\t" . $myalias->value() . "\n";
		$tekst = $tekst .  "type\t" . $myalias->type() . "\n";
		$tekst = $tekst .  "------------------------------------------------------------------------------\n";
	}
	return $tekst;
}

sub printwaardes {
	my $tekst = "";
	foreach my $myalias (@Aliases) {
		$tekst = $tekst . "titel\t" . $myalias->titel() . "\n";
		$tekst = $tekst .  "waarde\t" . $myalias->waarde() . "\n";
		if ($myalias->type() eq "datum") {
			$tekst = $tekst .  "shift\t" . $myalias->datumshift() . "\n";
		}
		$tekst = $tekst .  "------------------------------------------------------------------------------\n";
	}
	return $tekst;
}

sub nrofaliases {
	scalar @Aliases
}

sub aliases {
	@Aliases
}

1;