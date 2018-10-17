package RenameFiles::Aliases;

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
use constant { true => 1, false => 0 };

our $VERSION = '1.0';

# lege waarde
my $empty = "[empty]";

# title		exif-tag in file consists mostly of tagname:group
# default	if not set
# alias		value can be used when set exif-tag
# type		if type date, then the exif-date value can be added or subtracted by a certain value
# value		the value as set in the exif-tag
#
# written	(default false) set to true when this tag is set and written into the file
# exif_title 	(default false) set to true if the exif-title in subject corresponds with each other
# exif_date 	(default false) set tot true if the exif-date in subject corresponds with each other

my @Aliases;

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->{written} = false;
	$self->_init;
	return $self;
}

sub _init {
	my $self = shift;
	push @Aliases, $self;
}

sub title {
	my $self = shift;
	return $self->{title} || $empty;
}


sub title_tagname {
	my $self = shift;
	my $title_tagname = $self->title();
	my @titles = split /\:/, $self->title();
	if ($#titles > 0) {
		$title_tagname = $titles[1];
	}
	return $title_tagname;
}

sub title_group {
	my $self = shift;
	my $title_group = $empty;
	my @titles = split /\:/, $self->title();
	if ($#titles > 0) {
		$title_group = $titles[0];
	}
	return $title_group;
}
	

sub default {
	my $self = shift;
	return $self->{default} || $empty;
}

sub alias {
	my $self = shift;
	return $self->{alias} || $empty;
}

sub type {
	my $self = shift;
	return $self->{type} || $empty;
}

sub value {
	my $self = shift;
	return $self->{value} || $empty;
}

sub written {
	my $self = shift;
	$self->{written} = true;
}

sub notwritten {
	my $self = shift;
	$self->{written} = false;
}

sub iswritten {
	my $self = shift;
	return ($self->{written} == true);
}

sub isexif_title {
	my $self = shift;
	my $exif_title = shift;
	my $found = false;
	if (defined $exif_title) {
		if ($exif_title eq $self->title_tagname()) {
			$found = true;
		}
	}
	return ($found eq true);
}

sub isexif_datetime {
	my $self = shift;
	my $exif_datetime = shift;
	my $found = false;
	if (defined $exif_datetime) {
		if ($exif_datetime eq $self->title_tagname()) {
			$found = true;
		}
	}
	return ($found eq true);
}

sub clear {
	my $self = shift;
	$self->{value} = $empty;
}

sub clearall {
	foreach my $myalias (@Aliases) {
		$myalias->clear();
	}
}

sub setvalue_for_alias {
	shift;
	my $value = shift || $empty;
	my $alias = shift || $empty;
	my $found = false;
	foreach my $myalias (@Aliases) {
		if ($myalias->{alias} eq $alias) {
			$myalias->{value} = $value;
			$found = true;
		}
	}
	return $found == true;
}

sub setvalue_for_title {
	shift;
	my $title = shift || $empty;
	my $value = shift || $empty;
	my $found = false;
	foreach my $myalias (@Aliases) {
		if ($myalias->{title} eq $title) {
			$myalias->{value} = $value;
			$found = true;
		}
	}
	return $found == true;
}

sub value_or_default {
	my $self = shift;
	my $value = $empty;
	if (($self->value() ne $empty) || ($self->default() ne $empty)) {
		if ($self->value() ne $empty) {
			$value = $self->value()
		} else {
			$value = $self->default()
		}
	}
	return $value;
}

sub absvalue_or_default {
	my $self = shift;
	my $value = $empty;
	if (($self->value() ne $empty) || ($self->default() ne $empty)) {
		if ($self->value() ne $empty) {
			$value = $self->value()
		} else {
			$value = $self->default()
		}
		if ($self->type() eq "datetime") {
			if (substr($self->value(), 0, 1) eq "-") {
				$value = substr($self->value(), 1, length($self->value())-1);
			} else {
				$value = $self->value();
			}
		}
	}
	return $value;
}

sub dateshift {
	my $self = shift;
	my $shift = 0;
	if (($self->value() ne $empty) || ($self->default() ne $empty)) {
		if ($self->type() eq "datetime") {
			if (substr($self->value(), 0, 1) eq "-") {
				$shift = -1;
			} else {
				$shift = 1;
			}
		}
	}
	return $shift;
}

sub datetime_value {
	my $self = shift;
	my $timeshift = undef;
# check if timeshift is set
	if (($self->type() eq "datetime") && ($self->value_or_default() ne $empty)) {
# extract minus sign if applicable
		my $tempvalue = $self->absvalue_or_default();
# check if datetime_end has proper format
		if ($tempvalue =~ m/\d{2}:\d{2}:\d{2}/) {
			my $format = DateTime::Format::Strptime->new(pattern => "%H:%M:%S");
			$timeshift = $format->parse_datetime($tempvalue);
			if (!($timeshift)) {
				$self->seterror("warning", sprintf("timeshift %s is not correct", $self->value_or_default()));
#				$self->{datetime_error} = true;
			}
		} else {
			$self->seterror("warning", sprintf("timeshift %s has not a proper format", $self->value_or_default()));
#			$self->{datetime_error} = true;
		}
	}
	return $timeshift;
}

sub printall {
	my $tekst = sprintf("%-35s %-25s %-25s %-25s %-8s\n", "title", "default", "alias", "value", "type");
	$tekst = $tekst . "----------------------------------- ------------------------- ------------------------- ------------------------- -------- \n";
	foreach my $myalias (@Aliases) {
		$tekst = $tekst . sprintf("%-35s %-25s %-25s %-25s %-8s\n", $myalias->title(), $myalias->default(), $myalias->alias(), $myalias->value(), $myalias->type());
	}
	$tekst = $tekst . "----------------------------------- ------------------------- ------------------------- ------------------------- -------- \n";
	return $tekst;
}

sub printvalues {
	my $tekst = sprintf("%-35s %-30s %-5s\n", "title", "value", "shift");
	$tekst = $tekst . "----------------------------------- ------------------------------ ----- \n";
	foreach my $myalias (@Aliases) {
		$tekst = $tekst . sprintf("%-35s %-30s %-5s\n", $myalias->title(), $myalias->absvalue_or_default(), $myalias->dateshift);
	}
	$tekst = $tekst . "----------------------------------- ------------------------------ ----- \n";
	return $tekst;
}

sub nrofaliases {
	scalar @Aliases
}

sub aliases {
	@Aliases
}

1;