;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Performs moving, deleting, copying, renaming files

;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon
#SingleInstance force
The_ProjectName := "FilePidgin"

;Dependencies
; npm
#Include %A_LineFile%\..\node_modules
#include util-misc.ahk\export.ahk
; #include util-array.ahk\export.ahk
#include transformStringVars.ahk\export.ahk
#Include biga.ahk\export.ahk
#Include json.ahk\export.ahk
#Include notify.ahk\export.ahk
#Include logs.ahk\export.ahk
#Include wrappers.ahk\export.ahk


;/--\--/--\--/--\--/--\--/--\
; Global Vars
;\--/--\--/--\--/--\--/--\--/
;; Define global variables like settings location
Settings_FilePath := A_ScriptDir "\settings.json"
AllFiles_Array := []
Errors := []


; global objects
A := new biga()
;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Check for CommandLineArguments
if (A.include(A_Args,"auto")) {

}

;; Import and parse any settings files
settingsFiles := fn_dirObj(A_ScriptDir "\*.json")
for _, value in settingsFiles {
	FileRead, theMemoryFile, % value
	theSettings := JSON.parse(theMemoryFile)
	theMemoryFile := ;blank

	;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
	; MAIN
	;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

	; if !DEBUG and settings file has parsing object
	if (!DEBUG && theSettings.parsing) {

		;; Create Logging obj
		log := new Log_class(The_ProjectName "-" A_YYYY A_MM A_DD, theSettings.logfiledir)
		log.maxNumbOldLogs_Default := 0 ; keep adding to the same log per day
		log.application := The_ProjectName
		log.preEntryString := "%A_NowUTC% -- "
		log.initalizeNewLogFile(false, The_ProjectName " v" The_VersionNumb " log begins...`n")
		log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

		; create legacy style global TOD_ TOM_ style variables - fix if possible
		fn_globalDateFactory()
		exportpath := transformStringVars(theSettings.exportpath)
		;; parse files
		data := sb_Parse(theSettings)
		; count number of files
		if (A.size(data) != 0) {
			; export list of files being worked on
			exportList := A.join(A.pick(data, ["filePath", "actions"]), "`n")
			dateObj := fn_globalDateFactory()
			FileAppend, %exportList% "`n", % logfiledir The_ProjectName "-" dateObj.YYYY dateObj.MM dateObj.DD "-files.log"
			Notify(The_ProjectName, "performing actions on " A.size(data) " files", , "GC=black TC=White MC=White")
			;; perform actions
			sb_performActions(data)
		}
	}
}
quitSeconds := 10
msg := "Completed all actions in settings. Exiting in " quitSeconds
Notify(The_ProjectName, msg, , "GC=black TC=White MC=White")
log.add(msg)
sleep, % quitSeconds * 1000
log.finalizeLog()
ExitApp, 1

;/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Top level functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
sb_Parse(param_settings)
{
	global log
	array := []
	log.add("Executing all setting parsers...")

	; param_settings
	param_settings.exportPath := fn_globalReachTransform(param_settings.exportPath)

	if (param_settings.parsing) {
		for key, value in param_settings.parsing {

			; quit if no pattern is defined
			if (A.isUndefined(value.pattern)) {
				return []
			}

			;convert string in settings file to a fully qualifed var + string for searching
			if (value.recursive) {
				recursion := " R"
			} else {
				recursion := ""
			}
			searchString := transformStringVars(value.pattern)
			log.add("Searching for files matching: " searchString)
			; EACH FILE
			; EACH FILE
			; EACH FILE
			loop, Files, %searchString%, % recursion
			{
				flag := false
				item := fileProperties(A_LoopFilePath)

				;; modifed age
				if (value.age && A.includes(["d", "m", "h"], A.last(value.age))) {
					ageTarget := A.parseInt(A.join(A.dropRight(value.age), ""))
					if (fn_fileAge(A_Now, item.fileTimeC) > ageTarget, "days") {
						flag := true
					}
				}
				;; filename alone
				; do not allow wildcard selection of delete files without age
				if (A.isUndefined(value.age) && (!A.includes(value.actions, "delete"))) {
					continue
				}
				if (A.includes(value.actions, "move")) {
					flag := true
					; transform moveto path if needed
					value.moveto := fn_globalReachTransform(value.moveto)
				}

				;; ACTION
				if (flag == true) {
					array.push({"filePath": A_LoopFilePath, "actions": value.actions, "moveto:": value.moveto})
					log.add(A_LoopFileName " Added to actionable files")
				}
			}
		}
	} else {
		msg("No .\settings.json file found`n`nThe application will quit.")
		log.add("Quit due to missing settings file.", "FATAL")
		log.finalizeLog(The_ProjectName . " log ends.")
		ExitApp, 1
	}
	return array
}


sb_performActions(param_data)
{
	global log

	if (Settings.exportPath) {
		FileCreateDir(Settings.exportPath)
	}

	for key, value in param_data {
		; delete
		if (A.includes(value.actions, "delete")) {
			log.add("Attempting to delete: " item.filePath)
			if (!FileDelete(value.filePath)) {
				log.add("Error encountered when attempting to delete: " item.filePath " (file in use, access denied, etc) Debug info: " Errorlevel)
			}
		}

		; move files
		if (A.includes(value.actions, "move") && A.size(value.moveto) > 3) {
			FileMove(value.filePath, moveto)
			; log.add("Attempting to move: " item.filePath)
		}

		; copy files
		if (A.includes(value.actions, "copy") && A.size(value.moveto) > 3) {
			FileMove(value.filePath, moveto)
			; log.add("Attempting to move: " item.filePath)
		}
	}
}



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

fn_globalReachTransform(param_string){
	global

	return transformStringVars(param_string)
}

;/--\--/--\--/--\--/--\--/--\
; GUI
;\--/--\--/--\--/--\--/--\--/


;/--\--/--\--/--\--/--\--/--\
; Small functions
;\--/--\--/--\--/--\--/--\--/

fn_getFileTimes(param_filePath)
{
	; prepare
	l_output := {}
	if (!fileExist(param_filePath)) {
		return l_output
	}

	FileGetTime, OutputMod, % param_filePath
	l_output.modifiedTime := OutputMod

	FileGetTime, OutputCre, % param_filePath, C
	l_output.createdTime := OutputCre

	FileGetTime, OutputAcc, % param_filePath, A
	l_output.accessTime := OutputAcc

	return l_output
}


fn_fileAge(param_time1, param_time2, param_unit:="days")
{
	Diff := param_time2
	Diff -= param_time1, %param_unit%
	return abs(Diff)
}


fn_timeDifference(param_time1, param_time2, param_unit:="seconds")
{
	Diff := param_time2
	Diff -= param_time1, %param_unit%
	return Diff
}

fn_globalDateFactory(param_day:="", param_offset:=0) {
	global

	if (param_day == "") {
		param_day := A_Now
	}
	param_day += param_offset, "days"

	; create
	; year
	TOD_YYYY := FormatTime(param_day, "yyyy")
	TOD_YY := FormatTime(param_day, "yy")

	; month
	TOD_MM := FormatTime(param_day, "MM")
	TOD_M := FormatTime(param_day, "M")

	; day
	TOD_DD := FormatTime(param_day, "dd")
	TOD_D := FormatTime(param_day, "d")


	; legacy "tomorrow"
	param_day += 1, "days"
	; year
	TOM_YYYY := FormatTime(param_day, "yyyy")
	TOM_YY := FormatTime(param_day, "yy")

	; month
	TOM_MM := FormatTime(param_day, "MM")
	TOM_M := FormatTime(param_day, "M")

	; day
	TOM_DD := FormatTime(param_day, "dd")
	TOM_D := FormatTime(param_day, "d")

	return
}


fn_DateFactory(param_day:="", param_offset:=0) {
	if (param_day == "") {
		param_day := A_Now
	}
	param_day += param_offset, "days"

	; prepare
	output := {}


	; create
	; year
	output.YYYY := FormatTime(param_day, "yyyy")
	output.YY:= FormatTime(param_day, "yy")

	; month
	output.MM := FormatTime(param_day, "MM")
	output.M := FormatTime(param_day, "M")

	; day
	output.DD := FormatTime(param_day, "dd")
	output.D := FormatTime(param_day, "d")

	return output
}

; v.90
fileProperties(sFile:="") {
	if (!FileExist(sFile)) {
		return false
	}

	Loop, Files, % sFile
	{
		_FileExt := ""
		SplitPath, sFile, _FileExt, _Dir, _Ext, _File, _Drv

		l_data := {}
		l_data["attrib"]    := A_LoopFileAttrib
		l_data["dir"]       := _Dir
		l_data["drv"]       := _Drv
		l_data["ext"]       := _Ext
		l_data["file"]      := _File
		l_data["file.Ext"]  := _FileExt
		l_data["filePath"]  := sFile
		l_data["fileSize"]  := A_LoopFileSize
		l_data["fileTimeA"] := A_LoopFileTimeAccessed
		l_data["fileTimeC"] := A_LoopFileTimeCreated
		l_data["fileTimeM"] := A_LoopFileTimeModified
		break
	}
	return l_data
}


fn_dirObj(param_dirPattern:="") {
	if (param_dirPattern == "") {
		param_dirPattern := A_LineFile
	}

	l_arr := []
	Loop, %param_dirPattern%,
	{
		l_arr.push(A_LoopFileFullPath)
	}
	return l_arr
}
