Overview
This tool moves files around depending on user configuration via *.json files in the same directory

Example Use
Move files from "\\10.0.0.1\data" to "Z:\ZIPPED\%TOM_MM%-%TOM_DD%-%TOM_YY%\"

# Settings
settings json files require elements of the following:

exportPath

logfiledir

an object that describes the files to be copied and where to find them


## Parsing Objects:


name

dir

filepattern

age (Optional)

association	string	(Optional)

renames	object	(Optional)

actions	array	(Optional)


Optional: Actions:
delete


## Command Line Arguments:

Two commandline arguments are allowed. If supplying both they should be separated with a pipe character "|"

The order does not matter.


**Date:** A date following the {{YYYYMMDD}} format can be supplied to give the program a certain date to use for it's internal variables when used for filename matching specific (or generic) dates


**Setting location:** a filepath can be supplied. Normally the app will look for a settings file within it's own ./ directory. When a full physical/network path is supplied, that will be used instead. For example "\\mynetworklocation\Tools\Ops_fileshuffle\settings.json"

## Warnings & Troubleshooting:

This application can delete files
