#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
FileEncoding, UTF-8

SteamPath := "C:\Program Files (x86)\Steam"
AdditionalPaths := ["Steam", "Riot", "Origin", "Battle"]

; Get Steam:
while FileExist(SteamPath . "\steamapps\libraryfolders.vdf") != "" {
	FileSelectFolder, %SteamPath%, "*" + %SteamPath%, 1, "Inavlid Steam installation.`nSelect Valid Steam install folder!`nDefault: C:\Program Files (x86)\Steam"
	SteamPath := RegExReplace(SteamPath, "\\$")
}

LibFilePath := "" . SteamPath . "\steamapps\libraryfolders.vdf" . ""
LibFilePath := "" "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf" . ""

; Get Game folders from Steam:
LibPaths := Array()
FileOpen(LibFilePath, 0)
FileRead, LibFile, LibFilePath
if ErrorLevel {
	;MsgBox % "ERROR:" . A_LastError
}
Loop, Parse, % LibFile, `n, `r 
{
	FoundPos := InStr(%A_Index%, `"path`", true, 1)
	if (FoundPos != 0) {
		MsgBox
		LibPaths.Push(SubStr(SubStr(%A_Index%, FoundPos + 9), 1, -1))
	}
}
LibPaths.Push(AdditionalPaths*)

for i, KeyWord in LibPaths
{
	test := test . ", " . KeyWord
}
;MsgBox % test

Hotkey, $<!F4, HahaNo, Off
Hotkey, $<^>!F4, DoIt, On

while (1>0)
{
	WinGet, WinPath, ProcessPath, A
	HasWord := false
	for i, KeyWord in LibPaths
	{
		HasWord := HasWord || InStr(WinPath, KeyWord, false)
		if HasWord {
			break
		}
	}
	if HasWord {
		Hotkey, <!F4, On
		sleep, 5000
	} else {
		Hotkey, <!F4, Off
	}
	sleep, 1000
}

ExitApp

HahaNo:
	MsgBox, No.
	
DoIt:
	SendInput !{F4}
