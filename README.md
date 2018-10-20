# RenameFiles
This Perl script is created in order to rename a bundle of files (can be phot, video, audio) in an approopriate format:
 		20100309-120501 Description.jpg
 
 However other variations are possible as well:
		20100309-001 Description.jpg
		Description.jpg
		NoDate-001 Description.jpg

Where possible it retrieves the information within the files with the help of exiftool, but it can also retrieve the date and time
from the pattern of the filename.

The configuration is made with an xml-file: start.xml whcih you can place in the same directory as the files
All files should be in one folder


## Content of start.xml
|level | tagname | number    |	description                                                                                                                        |
|:----:| ------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------- |
|1	   | config  | 1         |  all tags should be enclosed within the maintag `<config> ... </config>`, no additional attributes                                    |
|2	   | alias	 | 0 or more |	an alias is an easy way to set a set of exif-tags at once, and it's easier to remember, since you put all aliases	one time       |

|alias | attribute | default | description                                                                                                                         |
| ---- | --------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------- |
|      | title     |         | name of the exif-tag (groupname:tagname)                                                                                            |
|      | default   |         | if the alias is not set at subject-level, the default value is used                                                                 |
|      | type      |         | only necessary if it is of type *datetime*, in that case the value in this tag is taken as relative to the current date and time      |
|      | content   |         | the value between the tagnames, the alias itself, this can be any name as you wish, and can be used further on you can als use the same alias for multiple exif-tags |

|level | tagname   | number  | description                                                                                                        |
|:----:| --------- | ------- | ------------------------------------------------------------------------------------------------------------------ |
| 2    | convert   |1 or more| you set this tag for each search, a search is done like you do dir, eg *.jpg to find all files ending on .jpg      |

| convert |	attribute | default | description
| ------- | --------- |:-------:| ---------------------------------------------------------------------------------------------------------------------------------------- |
|         | filter    |	*.JPG   | the search for files                                                                                                                     |
|         |	numbering | T		| a number:	this is the starting number for the file, when you want a sequence of numbers. Any non number it takes the time of the file    |
|         | positions | 3       | it pads the number with zeros up to the choosen number of digits                                                                         |
|         |	subchar   | a       | in case two file will be renamed to the same name, it adds subchar after the number ot time in order to avoid overwriting of files. You can set to any character you want |
|         |	prefix    |         | instead of datetime you can use a fixed prefix                                                                                           |
|         |	overwrite_prefix |no| force to use prefix instead of datetime, even if it can be found in the exif-information                                                 |
|         |	exif-title|	Title   | name of the tag where to find the title for the description of the file                                                                  |
|         |	exif-datetime|DateTimeOriginal| name of the tag where to find the datetime of the file                                                                         |
|         |	exif-datetimeformat|%Y:%m:%d %H:%M:%S| the is the standard format, it's very unlikely to change it                                                             |
|         |	exif-timezone|TimeZone|	name of the tag where to find the timezone (if any) in the file                                                                        |
|         |	exif-timezoneformat|%H:%M| standard format, it's unlikely to change it                                                                                         |
|         |	pattern   |	%Y%m%d_%H%M%S |	sometimes the file doesn't have exif-info, but has the datetime information in the filename                                        |

|level | tagname | number    | description
|:----:| ------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| 3	   | subject | 1 or more | within the subject to you can differentiate files by timing. In a certain timeframe you can set another description for the file             |

| subject |	attribute |	default | description
| ------- | --------- |:-------:| ------------------------------------------------------------------------------------------------------------------------------------------ |
|         |	title     |         | the description for a file                                                                                                                 |
|         |	overwrite-title| no | you can force to use the title for the description instead of retrieving it from the exif-info                                             |
|         |	datetime-start|     | the datetime of a file should be more or equal to this value (can be `dd-mm-yyyy` or `dd-mm-yyyy hh:mm:ss`)                                    |
|         |	datetime-end |      | the datetime of a file should be less than this value (can be `dd-mm-yyyy` or `dd-mm-yyyy hh:mm:ss`)                                           |
|         |	timeshift |         | in case you set the time wrong you can shift the time in `hh:mm:ss`                                                                          |

|level | tagname | number       | description
|:----:| ------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| 4    | exif    | 0 or more    | if you want to write predefined information back into the exif-information of a file (makes the renaming slower)                          |

| exif | attribute | default    | description
| ---- | --------- |:----------:| ----------------------------------------------------------------------------------------------------------------------------------------- |
|      | title     |            | exif tagname unless alias is used                                                                                                         |
|      | alias-title |          | instead of exif tagname you can use the alias as set in the top of the config-file                                                        |
|      | type      |            | in case of a datetime field set it to *datetime*                                                                                            |
|      | content   |            | between tage, the value of the tagname with which the exif-info will be set                                                               |

In case of an error the information will be written in the file errors.txt in the same folder as the files

--------------

## Example

```xml
<config>
	<alias title="IPTC:Country-PrimaryLocationCode" default="NLD">Landcode</alias>
	<alias title="XMP:CountryCode" default="NLD">Landcode</alias>
	<alias title="IPTC:Country-PrimaryLocationName" default="Nederland">Land</alias>
	<alias title="XMP:Country" default="Nederland">Land</alias>
	<alias title="IPTC:Province-State" default="Zeeland">Provincie</alias>
	<alias title="XMP:State" default="Zeeland">Provincie</alias>
	<alias title="XMP:City" default="Goes">Stad</alias>
	<alias title="IPTC:subchar-location">Buurt</alias>
	<alias title="IPTC:ObjectName">Buurt</alias>
	<alias title="XMP:Title">Buurt</alias>
	<alias title="XMP:Headline">Omschrijving</alias>
	<alias title="ImageDescription">Omschrijving</alias>
	<alias title="XPSubject">Omschrijving</alias>
	<alias title="XPComment">Omschrijving</alias>
	<alias title="IPTC:Caption-Abstract">Omschrijving</alias>
	<alias title="XMP:Subject">Sleutels</alias>
	<alias title="XPKeywords">Sleutels</alias>
	<alias title="IPTC:Keywords">Sleutels</alias>
	<alias title="XMP:LastKeywordXMP">Sleutels</alias>
	<alias title="XMP:LastKeywordIPTC">Sleutels</alias>
	<alias title="IPTC:Writer-Editor" default="Author">Fotograaf</alias>
	<alias title="IPTC:By-line" default="Author">Fotograaf</alias>
	<alias title="XMP:CaptionWriter" default="Author">Fotograaf</alias>
	<alias title="XMP:Creator" default="Author">Fotograaf</alias>
	<alias title="EXIF:Artist" default="Author">Fotograaf</alias>
	<alias title="EXIF:XPAuthor" default="Author">Fotograaf</alias>
	<alias title="Photoshop:URL" default="website">URL</alias>
	<alias title="XMP:BaseURL" default="website">URL</alias>
	<alias title="EXIF:Copyright" default="Copyright (2018)">Copyright</alias>
	<alias title="IPTC:CopyrightNotice" default="Copyright (2018)">Copyright</alias>
	<alias title="XMP:Rights" default="Copyright (2018)">Copyright</alias>
	<alias title="IPTC:SpecialInstructions">Speciale instructies</alias>
	<alias title="XMP:Instructions">Speciale instructies</alias>
	<alias title="EXIF:DateTimeOriginal" type="datum">Datum</alias>
	<alias title="EXIF:CreateDate" type="datum">Datum</alias>
	<alias title="EXIF:ModifyDate" type="datum">Datum</alias>
	<convert filter="*.ARW" numbering="T" subchar="a" exif-datetime="CreateDate" exif-title="Title">
		<subject overwrite-title="yes" timeshift="-01:00:00" datetime-start="2017-02-11 17:00:00" datetime-end="2017-02-11 18:00:00" title="Dresden">
			<exif alias-title="Landcode">DEU</exif>
			<exif alias-title="Land">Duitsland</exif>
			<exif alias-title="Provincie">Sachsen</exif>
			<exif alias-title="Stad">Dresden</exif>
			<exif alias-title="Buurt">Centrum</exif>
			<exif alias-title="Omschrijving">Centrum</exif>
		</subject>
	</convert>
</config>
```
