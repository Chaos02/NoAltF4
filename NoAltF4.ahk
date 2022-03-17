#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
 #Warn  ; Enable warnings to assist with detecting common errors.
Process, Priority, , BelowNormal
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
FileEncoding, UTF-8

SteamPath := "C:\Program Files (x86)\Steam"
DefaultKeywords := ["Steam", "Riot", "Origin", "Battle"]




if (A_AHKVersion < "1.1.13") {
	Gui, Version:New, AlwaysOnTop -MinimizeBox -Resize, ERROR
	Gui, Version:Add, Link,, Error. Please download AHK > v1.1.13! `n (<a href="https://www.autohotkey.com/download/ahk-install.exe">Download</a>)
	Gui, Version:Show
	Return
	
	VersionGuiClose:
		ExitApp
}

ScriptVersion := "1.0.0"
DefaultAddKeyWords := "Key, words, here"
SplitPath, A_ScriptFullPath, , , , ScriptName
ConfigFile := A_AppData . "\" . ScriptName . ".ini"

InitialRun := false

Gosub ConfigRead

GuiCreated := false
Gosub GuiCreator

if (ShowSettings || InitialRun) {
	gosub Configure
}


; Self-schedule autostart:
FileCreateShortcut, A_ScriptDir/A_ScriptName, A_StartUp/A_ScriptName . "lnk", , , "Captures Alt+F4 from Programs with keywords in their path."

LibFilePath := "" . SteamPath . "\steamapps\libraryfolders.vdf" . ""
LibFilePath := "" "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf" . ""

LibPaths := Array()
if (GetFromSteam) {
	Gosub ReadSteamLibs
}

LibPaths.Push(DefaultKeywords*)

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
	Pause
	sleep, 1000
}

ExitApp


GuiCreator:

	if NOT (GuiCreated) {
		;Menu, TrayMenu, NoStandard ; Remove AHK Tray Menu entries
		Menu, Tray, Add, Configure
		Menu, Tray, Default, Configure
		; Menu, Tray, Color, 333333 ; Background Color of Tray Menu (goes away after hover >:/ )
		Menu, Tray, Click, 2 ; Doubleclick to activate default menu item
		Menu, Tray, Tip, % ScriptName
		Menu, Tray, Icon, % (A_WinDir . "\System32\SHELL32.dll"), 105, 1 ; Logo 105 = keys icon
	
		; FileGetVersion, ScriptVersion, A_ScriptFullPath
		
		Menu, OptionMenuMiscSubmenu, Add, &Open ConfigFile, OpenCfg,
		Menu, OptionMenuMiscSubmenu, Add, % ("&Stop " . ScriptName), Stop,
		Menu, OptionMenuMiscSubmenu, Add, , , ; seperator
		Menu, OptionMenuMiscSubmenu, Add, &Close, OptionsGuiClose,
		Menu, OptionMenuMiscSubmenu, Default, &Close
		Menu, OptionMenuBar, Add, &Miscellaneous, :OptionMenuMiscSubmenu,
		Menu, OptionMenuBar, Add, % ("v" . ScriptVersion), OpenGitHub, +Right
		GuiCreated := true
	}


	Gui, Options:New, +Border +Caption +DPIScale -Resize, % (ScriptName . " options")
	Gui, Options:Add, GroupBox, x2 y-1 w380 h90 cGray, Keywords
	Gui, Options:Add, Text, x12 y19 r1, % ("Built-in: " . ArrayJoin(DefaultKeywords))
	Gui, Options:Add, Edit, x12 y39 w360 h20 -Wrap -Multi -WantReturn gEditChange vKeywordsRaw, % DefaultAddKeyWords
	Gui, Options:Add, CheckBox, x14 y69 r1 vGetFromSteam Checked%GetFromSteam%, Import Libraries from Steam?
	Gui, Options:Add, CheckBox, x12 y99 r1 vShowSettings Checked%ShowSettings%, Show options again?
	Gui, Options:Add, Button, x200 y98 w80 h20 gResetOptions, Default
	Gui, Options:Add, Button, x300 y98 w80 h20 gGuiSave, Save
	Gui, Options:Menu, OptionMenuBar
	; Generated using SmartGUI Creator 4.0
	Return


ConfigRead:
	; initializes the ini file if it does not exist
	if NOT (FileExist(ConfigFile)) { 
		IniWrite, % DefaultAddKeyWords, % ConfigFile, Settings, "Keywords"
		IniWrite, false, % ConfigFile, Settings, "ShowCfg"
		IniWrite, true, % ConfigFile, Settings, "GetFromSteam"
		InitialRun := true
	}
	
	IniRead, KeywordsRaw, % ConfigFile, Settings, "Keywords"
	IniRead, ShowSettings, % ConfigFile, Settings, "ShowCfg"
	IniRead, GetFromSteam, % ConfigFile, Settings, "GetFromSteam"
	
	AdditionalKeywords := Array()
	AdditionalKeywords := StrSplit(KeywordsRaw, ",", " `t")
	AdditionalKeywords.Delete("Key")
	AdditionalKeywords.Delete("words")
	AdditionalKeywords.Delete("here")
	Return

ConfigWrite:
	IniWrite, % ("" . KeywordsRaw . ""), % ConfigFile, Settings, "Keywords"
	IniWrite, % ShowSettings, % ConfigFile, Settings, "ShowCfg"
	IniWrite, % GetFromSteam, % ConfigFile, Settings, "GetFromSteam"
	Return

OpenGitHub:
	Run, open "https://github.com/Chaos02/NoAltF4InGames"
	Return

OpenCfg:
	Run, % ("open " . ConfigFile)
	Return

Configure:
	Gosub ConfigRead
	Gui, Options:Show, Center AutoSize, % (ScriptName . "options")
	Loop 6 {
		Gui Flash
		Sleep 500
	}
	Return

ResetOptions:
	FileDelete, % ConfigFile
	Gosub ConfigRead
	Gui, Options:Destroy
	Gosub GuiCreator
	Return

EditChange:
	
	Return

GuiSave:
	Gui, Options:Submit, NoHide
	AdditionalKeywords := Array()
	AdditionalKeywords := StrSplit(KeywordsRaw, ",", " `t")
	if (ErrorLevel) {
		MsgBox, "Input invalid! Please try again!`nFormat: Steam, Origin, etc..."
	} else {
		Gui, Options:Hide
		Gosub ConfigWrite
	}
	Return

MoreOpts:
	
	Return

OptionsGuiClose:
	Gui, Options:Hide
	Return

ReadSteamLibs:
	; Get Game folders from Steam:
	FileOpen(LibFilePath, 0)
	FileRead, LibFile, LibFilePath
	if ErrorLevel {
		MsgBox % "ERROR:" . A_LastError
		ErrorLevel := 0
	}
	Loop, Parse, % LibFile, `n, `r 
	{
		FoundPos := InStr(%A_Index%, "" . "path" . "", true, 1)
		if (FoundPos != 0) {
			LibPaths.Push(SubStr(SubStr(%A_Index%, FoundPos + 9), 1, -1))
		}
	}
	Return

Stop:
	ExitApp

HahaNo:
	MsgBox, No.
	Return
	
DoIt:
	SendInput !{F4}
	Return


ArrayJoin( strArray )
{
  Str := strArray[1]
  for Counter,Entry in strArray
    Str = Str . ", " . Entry
  return Str
}
