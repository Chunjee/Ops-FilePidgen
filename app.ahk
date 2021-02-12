;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Performs moving, deleting, renaming files

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
	AUTOMODE := true
}
for _, value in A_Args {
	if (fn_QuickRegEx(CL_Args[A_Index],"(\d{8})") != "") {
		The_CustomDate := CL_Args[A_Index]
	}
}

;;Import and parse settings file
FileRead, The_MemoryFile, % Settings_FilePath
Settings := JSON.parse(The_MemoryFile)
The_MemoryFile := ;blank
; Array_Gui(Settings)

;; Create Logging obj
log := new Log_class(The_ProjectName "-" A_YYYY A_MM A_DD, Settings.logfiledir)
log.maxNumbOldLogs_Default := -1 ; keep adding to 1 log per day
log.application := The_ProjectName
log.preEntryString := "%A_NowUTC% -- "
log.initalizeNewLogFile(false, The_ProjectName " v" The_VersionNumb " log begins...`n")
log.add(The_ProjectName " launched from user " A_UserName " on the machine " A_ComputerName ". Version: v" The_VersionNumb)

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
if (!DEBUG) {
	data := sb_Parse(Settings)
	sb_MoveFiles(data)

	quitSeconds := 10
	msg := "Completed all actions in settings. Exiting in " quitSeconds
	Notify(The_ProjectName, msg)
	log.add(msg)
	sleep, % quitSeconds * 1000
	log.finalizeLog()
	ExitApp, 1
}


sb_Parse(Settings)
{
	global log
	array := []
	log.add("Executing all setting parsers...")

	Settings.exportPath := transformStringVars(Settings.exportPath)
	if (Settings.parsing) {
		for key, value in Settings.parsing {
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
				; msgbox, % A.print(item)

				; modifed age
				if (value.age && A.includes(["d", "m", "h"], A.last(value.age))) {
					ageTarget := A.parseInt(A.join(A.dropRight(value.age), ""))
					if (fn_fileAge(A_Now, item.fileTimeC) > ageTarget, "days") {
						flag := true
					}
				}

				; ACTION
				if (flag == true) {
					array.push({"filePath": A_LoopFilePath, "actions": value.actions})
					log.add(A_LoopFileName " Added to list of files")
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


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Move files
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
sb_MoveFiles(param_data)
{
	if (Settings.exportPath) {
		FileCreateDir(Settings.exportPath)
	}

	; count number of files
	Notify("FilePidgin", "performing actions on " A.size(param_data) " files")

	for key, value in param_data {
		; delete
		if (A.includes(value.actions, "delete")) {
			msgbox, % A.print(value.actions)
			log.add("Attempting to delete: " item.filename)
			if (!FileDelete(value.filePath)) {
				log.add("Error encountered when attempting to delete: " item.filename " (file in use, access denied, etc) Debug info: " Errorlevel)
			}
		}
	}
}


;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Report Generation
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; FileDelete, %Options_DBLocation%\DB.json
; loop, % AllFiles_Array.MaxIndex() {
	; BLANK ATM
; }
; FileAppend, %The_MemoryFile%, %Options_DBLocation%\DB.json

;/--\--/--\--/--\--/--\--/--\--/--\--/--\
; WrapUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/
sb_wrapup() {
	if (Errors.MaxIndex() >= 1) {
		msg := Errors.MaxIndex() " Errors were encountered. Check logfiles for details at " Settings.logfiledir
		msg(msg)
		log.add(msg, "ERROR")
	} else {
		log.add("All files moved without errors.")
	}

	;Wrap up logs and Exit
	log.finalizeLog(The_ProjectName . " log ends.")
	ExitApp, 0
}

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/



;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
; Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

;Gets the timestamp out of a filename and converts it into a day of the week name
Fn_GetWeekName(para_String) ;Example Input: "20140730Scottsville"
{
	RegExMatch(para_String, "(\d{4})(\d{2})(\d{2})", RE_TimeStamp)
	if (RE_TimeStamp1 != "") {
		;dddd corresponds to Monday for example
		FormatTime, l_WeekdayName , %RE_TimeStamp1%%RE_TimeStamp2%%RE_TimeStamp3%, dddd
	}
	if (l_WeekdayName != "") {
		return l_WeekdayName
	} else {
		;throw error and return false if unsuccessful
		throw error
		return false
	}
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