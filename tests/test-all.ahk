
#NoTrayIcon
#SingleInstance, force
SetBatchLines, -1

DEBUG := true

#Include %A_ScriptDir%\..\app.ahk

#Include %A_ScriptDir%\..\node_modules
#Include unit-testing.ahk\export.ahk

#Include biga.ahk\export.ahk
#Include json.ahk\export.ahk
#Include wrappers.ahk\export.ahk

assert := new unittesting()

; --- Variables ---


;/--\--/--\--/--\--/--\--/--\
; MAIN
;\--/--\--/--\--/--\--/--\--/
assert.group("date generation")
assert.label("today")
result := fn_DateFactory(20210210)
assert.test(result.YYYY, 2021)
assert.test(result.YY, 21)
assert.test(result.MM, 02)
assert.test(result.M, 2)
assert.test(result.DD, 10)
assert.test(result.D, 10)

assert.label("tomorrow")
result := fn_DateFactory(20210210, 1)
assert.test(result.YYYY, 2021)
assert.test(result.YY, 21)
assert.test(result.MM, 02)
assert.test(result.M, 2)
assert.test(result.DD, 11)
assert.test(result.D, 11)


assert.group("date difference")
assert.label("negative days")
assert.test(fn_timeDifference(20210101, 20200101, "days"), -366)
assert.label("days with hours and min parameter")
assert.test(fn_timeDifference(20210101, 202001010015, "days"), -365)
assert.test(fn_timeDifference(202101010015, 20200101, "days"), -366)
assert.label("one year in days")
assert.test(fn_timeDifference(20210101, 20220101, "days"), 365)


assert.fullreport()
ExitApp
