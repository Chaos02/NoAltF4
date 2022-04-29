#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force
 #Warn  ; Enable warnings to assist with detecting common errors.
Process, Priority, , BelowNormal
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
FileEncoding, UTF-8
Gui, Font, , "Lucida Console"

SteamPath := "C:\Program Files (x86)\Steam"
DefaultKeywords := ["Steam", "Riot", "Origin", "Battle"]



;@Ahk2Exe-IgnoreBegin
if (A_AHKVersion < "1.1.13") {
	Gui, Version:New, AlwaysOnTop -MinimizeBox -Resize, ERROR
	Gui, Version:Add, Link,, Error. Please download AHK > v1.1.13! `n (<a href="https://www.autohotkey.com/download/ahk-install.exe">Download</a>)
	Gui, Version:Show
	Return

	VersionGuiClose:
		ExitApp
}
;@Ahk2Exe-IgnoreEnd

ScriptVersion := "1.0.0rc-3"
;@Ahk2Exe-Let U_version = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetProductVersion %U_version%
;@Ahk2Exe-SetFileVersion %U_version~\D+~.%
GHUser := "Chaos02"
;@Ahk2Exe-Let U_Author = %A_PriorLine~U)^(.+"){1}(.+)".*$~$2%
;@Ahk2Exe-SetCompanyName %U_Author%
;@Ahk2Exe-Obey U_ScriptName, SplitPath`, A_ScriptFullPath`, `, `, `, ScriptName
;@Ahk2Exe-SetProductName %U_ScriptName%
;@Ahk2Exe-ExeName %U_ScriptName%
;@Ahk2Exe-SetLanguage 0409
DefaultAddKeyWords := "Key, words, here"
SplitPath, A_ScriptFullPath, , , , ScriptName
ConfigFile := A_AppData . "\" . ScriptName . ".ini"
AutoStartFile := A_StartUp . "\" . ScriptName . ".lnk"

InitialRun := false
Notified := false
lastETag := "W/ack"
InclusionKeywords := Array()
AdditionalKeywords := Array()
SteamPaths := Array()

;	Hotkey, ^!P, Unpause

Gosub ConfigRead

MenuCreated := false
Gosub GuiCreator

if (ShowSettings || InitialRun) {
	gosub Configure
}

; Self-schedule autostart:
FileCreateShortcut, % A_ScriptFullPath, % AutoStartFile, , , "Captures Alt+F4 from Programs with keywords in their path."

LibFilePath := "" . SteamPath . "\steamapps\libraryfolders.vdf" . ""
; LibFilePath := "" . "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf" . ""


InclusionKeywords.Push(DefaultKeywords*)
InclusionKeywords.Push(AdditionalKeywords*)
if (GetFromSteam) {
	Gosub ReadSteamLibs
	InclusionKeywords.Push(SteamPaths*)
}

Hotkey, $<!F4, HahaNo, Off
Hotkey, $<^>!F4, DoIt, On

SetTimer, main, 1000

Gosub SetUpdateStatusIcon

#Persistent


; TODO: Replace Labels with functions:
/*
https://riptutorial.com/autohotkey/4062/use-functions-instead-of-labels

XYEvent(CtrlHwnd:=0, GuiEvent:="", EventInfo:="", ErrLvl:="") {
	GuiControlGet, controlName, Name, %CtrlHwnd%
	GuiControlGet, EditField
	MsgBox, %controlName% has been clicked
	MsgBox, Content is %EditField%
}

GuiClose(hWnd) {
	
}

*/

main:
	WinGet, WinPath, ProcessPath, A
	ListLines, Off
	HasWord := false
	For integerVar, KeyWord in InclusionKeywords
	{
		HasWord := HasWord || InStr(WinPath, KeyWord, false)
		if HasWord {
			break
		}
	}
	
	if HasWord {
		ListLines, On
		Hotkey, <!F4, On
		SetTimer, main, 2000
	} else {
		ListLines, On
		Hotkey, <!F4, Off
		SetTimer, main, 1000
	}
	Return

GuiCreator:
	if NOT (MenuCreated) {
		ListLines, Off
		;@Ahk2Exe-SetMainIcon NoAltF4.ico
		/*@Ahk2Exe-Keep
			Menu, Tray, NoStandard ; Remove AHK Tray Menu entries
			Menu, Tray, NoMainWindow ; Remove AHK Tray Menu entries
			;ScriptVersion := FileGetInfo(A_ScriptFullPath).ProductVersion ; TODO: get Version from own file details
			Menu, Tray, Icon, % A_ScriptFullPath, 1, 1 ;keys icon
		*/
		;@Ahk2Exe-IgnoreBegin
			Menu, Tray, Icon, Shell32.dll, 105, 1 ;keys icon
		;@Ahk2Exe-IgnoreEnd
		Menu, Tray, Add, Configure
		Menu, Tray, Default, Configure
		; Menu, Tray, Color, 333333 ; Background Color of Tray Menu (goes away after hover >:/ )
		Menu, Tray, Click, 1 ; single click to activate default menu item
		Menu, Tray, Tip, % ScriptName
		
		Menu, OptionMenuMiscSubmenu, Add, Set &deny message, OpenCfg,
		Menu, OptionMenuMiscSubmenu, Add, Set &override hotkey, OpenCfg, ;TODO
		Menu, OptionMenuMiscSubmenu, Add, , , ; seperator
		Menu, OptionMenuMiscSubmenu, Add, &Open config file, OpenCfg,
		Menu, OptionMenuMiscSubmenu, Add, % ("&Stop " . ScriptName), Stop,
		Menu, OptionMenuMiscSubmenu, Add, Show startup &entry, ShowStartup
		Menu, OptionMenuMiscSubmenu, Add, , , ; seperator
		Menu, OptionMenuMiscSubmenu, Add, &Close, OptionsGuiClose,
		Menu, OptionMenuMiscSubmenu, Default, &Close
		Menu, OptionMenuBar, Add, &Miscellaneous, :OptionMenuMiscSubmenu,
		Menu, OptionMenuBar, Add, Updater, ShowUpdater, +Right
		Menu, OptionMenuBar, Add, % ("v" . ScriptVersion), OpenHomePage, +Right
		
		ChangeLog := ""
		SetTimer, SetUpdateStatusIcon, % (1000 * 60 * 30) ; Run every 30 mins
		ListLines, On
		MenuCreated := true
	}
	
	ListLines, Off
	Gui, Updater:New, +Border +Caption +DPIScale -Resize, % (ScriptName . "` updater")
	Gui, Updater:Add, GroupBox, x2 y0 w380 h140, Changelog:
	Gui, Updater:Add, Button, x100 y150 w80 h20 gUpdaterRefresh, Refresh
	Gui, Updater:Add, Button, x200 y150 w80 h20 gAutoUpdater, Update
	Gui, Updater:Add, Button, x300 y150 w80 h20 gUpdaterGuiClose, Close
	Gui, Updater:Font, , Lucida Console
	Gui, Updater:Add, Edit, x12 y19 r9 w360 vLogChange +ReadOnly +Wrap, "Press Refresh for changelog."
	GuiControl, Font, Updater:LogChange
	
	Gui, Options:New, +Border +Caption +DPIScale -Resize, % (ScriptName . "` options")
	Gui, Options:Add, GroupBox, x2 y0 w380 h90, Keywords
	Gui, Options:Add, Text, x12 y14 r1 cGray, % ("Built-in: " . ArrayJoin(DefaultKeywords))
	Gui, Options:Add, Text, x12 y28 r1 cGray, % ("Steam: " . ArrayJoin(SteamPaths))
	Gui, Options:Add, Edit, x12 y44 w360 h20 -Wrap -Multi -WantReturn gEditChange vKeywordsRaw, % KeywordsRaw
	Gui, Options:Add, CheckBox, x14 y69 r1 gReadSteamLibs vGetFromSteam Checked%GetFromSteam%, Import Libraries from Steam?
	Gui, Options:Add, CheckBox, x12 y99 r1 vShowSettings Checked%ShowSettings%, Show options again?
	Gui, Options:Add, Button, x200 y98 w80 h20 gResetOptions, Default
	Gui, Options:Add, Button, x300 y98 w80 h20 gGuiSave, Save
	ListLines, On
	Gui, Options:Menu, OptionMenuBar
	; Generated using (also) SmartGUI Creator 4.0
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
	
	if (KeywordsRaw == "") {
		KeywordsRaw := DefaultAddKeyWords
	}
	
	AdditionalKeywords := StrSplit(KeywordsRaw, ",", " `t")
	For _iC, word in DefaultAddKeyWords {
		AdditionalKeywords.Delete(word)
	}
	Return

ConfigWrite:
	if (KeywordsRaw == "") {
		KeywordsRaw := DefaultAddKeyWords
	}
	IniWrite, % ("" . KeywordsRaw . ""), % ConfigFile, Settings, "Keywords"
	IniWrite, % ShowSettings, % ConfigFile, Settings, "ShowCfg"
	IniWrite, % GetFromSteam, % ConfigFile, Settings, "GetFromSteam"
	Return

OpenHomePage:
	Run, % ("open " . "https://github.com/" . GHUser . "/" . ScriptName)
	Return

OpenCfg:
	Run, % ("open " . ConfigFile)
	Return

Configure:
	Gosub ConfigRead
	Gui, Options:Destroy
	Gui, Updater:Destroy
	Gosub GuiCreator
	Gui, Options:Show, Center AutoSize, % (ScriptName . " options")
	Loop 3 {
		Gui Flash
		Sleep 500
	}
	Return

ResetOptions:
	FileDelete, % ConfigFile
	SteamPaths := Array()
	AdditionalKeywords := Array()
	Gosub Configure
	
	Return

EditChange:
	
	Return

GuiSave:
	ListLines, On
	Gui, Options:Submit, NoHide
	InclusionKeywords := DefaultKeywords
	if (GetFromSteam) {
		InclusionKeywords.Push(SteamPaths*)
	}
	AdditionalKeywords := Array()
	AdditionalKeywords := StrSplit(KeywordsRaw, ",", " `t")
	if (ErrorLevel) {
		MsgBox, "Input invalid! Please try again!`nFormat: Steam, Origin, etc..."
	} else {
		InclusionKeywords.Push(AdditionalKeywords*)
		Gui, Options:Hide
		Gosub ConfigWrite
	}
	;MsgBox, % Json.Dump(InclusionKeywords, , "  ")
	Return

MoreOpts:
	
	Return

OptionsGuiClose:
	ListLines, On
	Gui, Options:Hide
	Return

OptionsGuiEscape:
	Gui, Options:Hide
	Return

ReadSteamLibs:
	; Get Game folders from Steam:
	Gui, Options:Submit, NoHide
	SteamPaths := Array()
	if (GetFromSteam) {
		While NOT (FileOpen(LibFilePath, 256))
		{
			FileSelectFolder, %SteamPath%, "*" + %SteamPath%, 1, "Inavlid Steam installation.`nSelect Valid Steam install folder!`nDefault: C:\Program Files (x86)\Steam"
			SteamPath := RegExReplace(SteamPath, "\\$")
			LibFilePath := "" . SteamPath . "\steamapps\libraryfolders.vdf" . ""
		}
		if ErrorLevel {
			MsgBox % "ERROR:" . A_LastError
			ErrorLevel := 0
		}
		SteamLibFile := FileOpen(LibFilePath, 256)
		SteamPathRegex := "(?<=""path""\t\t)"".+"""
		
		While (NOT SteamLibFile.AtEOF) {
			ListLines, Off
			LibLine := SteamLibFile.ReadLine()
			LineWithPath := ""
			RegExMatch(LibLine, SteamPathRegex, LineWithPath)
			if (LineWithPath) {
				ListLines, On
				Path := RegExReplace(LineWithPath, "\\\\", "\")
				SteamPaths.Push(Path)
				ListLines, Off
			}
		}
		ListLines, On
	} else {
		SteamPaths := Array()
	}
	GuiControl, Text, Options:GetFromSteam, % ("Steam: " . ArrayJoin(SteamPaths))
	Return

Stop:
	ExitApp

Unpause:
	Pause, Toggle
	WinGet, WinPath, ProcessPath, A
	if (InStr(WinPath, "AutoHotkey")) {
		Send {F5}
	}
	Return


HahaNo:
	ListLines, On
	MsgBox, No. >:/
	Return

DoIt:
	ListLines, On
	SendInput !{F4}
	Return

versionCompare(vers1, vers2) {
	/*
		Returns true if the first version is greater than the second.
		TODO: Replace RegExReplace and afterwards check for keywords InStr()
	*/
	Version1 := StrSplit(RegExReplace(vers1, "\D+", ", "), ",", " `t`r`n")
	Version2 := StrSplit(RegExReplace(vers2, "\D+", ", "), ",", " `t`r`n")
	Loop, 4 {
		if (Version1[A_Index] == "") {
			Version1[A_Index] := "0"
		}
		if (Version2[A_Index] == "") {
			Version2[A_Index] := "0"
		}
	}
	
	Loop, 2 {
		if (Version2[A_Index] > Version1[A_Index]) {
			Return true
		}
	}
	if (Version1[3] == Version2[3]) {
		Return (Version1[4] == "0")
	}
	Return false
}

ArrayJoin(strArray) {
	Str := ""
	for Counter, Entry in strArray
		Str .= Entry . ", "
	return Trim(Str, ", ")
}

FormatList(Obj, IndentDepth:=0, IndentChar:="`t") {
	/*
		Written by https://github.com/Chaos02
		License: GPL-3.0
		Accepts: An ahk object/obj-based-array and how "deep" to pad with IndentChar
		Returns: A block string, resembling a list, with optional padding on the left. Powershell style.
	*/
	MaxKeyLen := 0
	MaxValLen := 0
	For key, val in Obj
	{
		tmp := StrLen(key)
		if (tmp > MaxKeyLen) {
			MaxKeyLen := tmp
		}
		tmp := StrLen(val)
		if (tmp > MaxValLen) {
			MaxValLen := tmp
		}
	}
	
	Indent :=
	while (StrLen(Indent) < (IndentDepth * StrLen(IndentChar))) {
		Indent := Indent . IndentChar
	}
	
	FList := Indent
	For key, val in Obj
	{
		FList := FList . StringPad(key, MaxKeyLen) . " : " . StringPad(val, MaxValLen, "L") . "`n" . Indent
	}
	FList := RegExReplace(FList, ")\s*$") ;Removes last newline + whitespaces TODO: maybe also indentation...
	Return FList
}

StringPad(Str, n, side:="R", char:=" ", MaxStrLen:=40) {
	/*
		Written by https://github.com/Chaos02
		License: GPL-3.0
		Accepts: A string which is to be padded up to n with char and a MaxStrLen.
		Returns: A char padded string.
		Meant to be used with a Monospace font. all characters need to be the same width.
	*/
	if (StrLen(Str) > MaxStrLen) {
		Str := SubStr(Str, 1, ((MaxStrLen // 2) - 1 )) . "..." . SubStr(Str, ((MaxStrLen // 2) + 3))
	}
	Switch side {
		Case "R":
			while (StrLen(Str) < n) {
			Str := Str . char
			}
		Case "L":
			while (StrLen(Str) < n) {
			Str := char . Str
			}
		Case "B":
			while (StrLen(Str) < n) {
			Str := char . Str . char
			}
			Str := SubStr(Str, 1, n)
	}
	Return Str
}

ObjectToString(Obj, ObjDepth:=0, IndentChar:="`t") {
	ObjString := Obj.Name
	/*
	if (ObjDepth < 1) {
		Tmp := Object()
		Tmp.Push(Obj*)
		ObjString := %A_ThisFunc%(Tmp, ObjDepth + 1, IndentChar)
		Tmp :=
	}
	*/
	ObjDepth++
	Tmp := Object()
	For key, val in Obj
	{
		key := RegExReplace(key, "\R", "``n``r")
		key := RegExReplace(key, "\t", "``t")
		if IsObject(val) {
			ObjString := ObjString . FormatList(Object(key, ""), ObjDepth, IndentChar) . "`n" . %A_ThisFunc%(val, ObjDepth, IndentChar)
		} else {
			val := RegExReplace(val, "\R", "``n``r")
			val := RegExReplace(val, "\t", "``t")
			Tmp[key] := val ; Adds all properties to tmp associative array for FormatList()
		}
	}
	ObjString := ObjString . "`n" . FormatList(Tmp, ObjDepth, IndentChar)
	Return ObjString
}

ReadLine(StringVar, LineNumber)
{
	StringPerLine := Array()
	Loop, Parse, StringVar, "`n", "`r"
	{
		StringPerLine[A_Index] := A_LoopField
	}
	if (LineNumber == "*") {
		Return StringPerLine
	} else {
		Return StringPerLine[LineNumber]
	}
}

ShowStartup:
	ListLines, On
	Run, % ("properties " . AutoStartFile)
	Return

CheckUpdate(localVersion, GitHubUser, repoName, versionControl, branch:="main")
{
	Global MenuCreated
	if (MenuCreated) {
		ErrorLevel := 0
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		URL := "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . branch . "/" . versionControl
		WebRequest.Open("GET", URL, true)
		try {
		WebRequest.Send()
		WebRequest.WaitForResponse()
		} catch HttpErr {
			Return "WinHttp: " . HttpErr
		}
		UpStreamVersion := WebRequest.ResponseText ; TODO: swap with latest release tag
		if NOT (ErrorLevel) { ; TODO: find source of ErrorLevel.
			Return versionCompare(localVersion, UpStreamVersion)
		} else {
			Return ErrorLevel
		}
	} else {
		Return False
	}
}

SetUpdateStatusIcon:
	UpdateStatus := CheckUpdate(ScriptVersion, GHUser, ScriptName, "version")
	Menu, OptionMenuBar, Rename, 2&, Updater
	Switch UpdateStatus {
		Case 1:
			Menu, OptionMenuBar, Icon, 2&, Shell32.dll, 147, 16 ; Update icon
			Menu, Tray, Tip, % (ScriptName . "`nUpdate available!")
			if NOT (Notified) {
				TrayTip, % (ScriptName . " Update available!"), An Update is available!`nDownload it through the Updater Gui!, 5
				Notified := true
			}
		Case false:
			Menu, Tray, Tip, % ScriptName
			Menu, OptionMenuBar, NoIcon, 2&, ; blank
		Default:
			Menu, Tray, Tip, % (ScriptName . "`nUpdater ERROR: " . UpdateStatus)
			Menu, OptionMenuBar, Icon, Updater, Shell32.dll, 128, 16 ;RedCross icon
			Menu, OptionMenuBar, Rename, 2&, % ("Updater (error: " . UpdateStatus . ")")
	}
	Return

ShowUpdater:
	Gui, Updater:Show, Center AutoSize, % (ScriptName . " Updater")
	Gui, Updater:+OwnerOptions

	Gosub UpdaterRefresh

	Return

UpdaterGuiClose:
	Gui, Updater:Hide
	Return

UpdaterRefresh:
	;SetCursor("WAIT")	;TODO: mostly gets stuck.. >:/
	Gosub SetUpdateStatusIcon
	ChangeLog := GetChangeLog(GHUser, ScriptName, 5)
	GuiControl, Updater:, LogChange, % ChangeLog
	;SetCursor("ARROW")
	Return

SetCursor(CursorName := "ARROW", ReplacedCursor := "ARROW") {
	;Replace ReplacedCursor with CursorName
	; https://www.autohotkey.com/board/topic/32608-changing-the-system-cursor/
	
	StringUpper, CursorName, CursorName
	StringUpper, ReplacedCursor, ReplacedCursor
	
	Cursors := Object("ARROW"	, 32512
				,"IBEAM"		, 32513
				,"WAIT"			, 32514
				,"CROSS"		, 32515
				,"UPARROW"		, 32516
				,"SIZE"			, 32640
				,"ICON"			, 32641
				,"SIZENWSE"		, 32642
				,"SIZENESW"		, 32643
				,"SIZEWE"		, 32644
				,"SIZENS"		, 32645
				,"SIZEALL"		, 32646
				,"NO"			, 32648
				,"HAND"			, 32649
				,"APPSTARTING"	, 32650
				,"HELP"			, 32651)
	
	Replacor := Cursors[CursorName]
	Replaced := Cursors[ReplacedCursor]
	
	try {
	CursorHandle := DllCall( "LoadCursor", Uint,0, Int, Replacor )
	ErrorLevel := DllCall( "SetSystemCursor", Uint, CursorHandle, Int, Replaced )
	} catch {
		throw Exception(ErrorLevel)
	}
	Return ErrorLevel
	;Reload system cursors (Restore)
	;SPI_SETCURSORS := 0x57
	;DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

WordWrap(strinput, intwidth, indent:="  ") {
	if (StrLen(strinput) <= intwidth) {
		Return strinput
	} else {
		LastSpace := InStr(strinput, " ",, -1 * intwidth)
		if (NOT LastSpace) {
			Return strinput
		}
	}
	Return SubStr(strinput, 1, LastSpace - 1) . "`n" . indent . %A_ThisFunc%(SubStr(strinput, LastSpace + 1), intwidth, indent)
}

GetChangeLog(GitHubUser, repoName, ChangeLogDepth:=1, Init:=true, WindowWidth:=54) {
	Global lastETag
	if (Init) {
		;CreateFormData(ReleasesRaw, ReleasesHeader, requestQuery)
		URL := "https://api.github.com/repos/" . GitHubUser . "/" . repoName . "/releases?page=1&per_page=" . ChangeLogDepth
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		; true for asynchronously, false for synchronously. Async lets Send wait for response
		WebRequest.Open("GET", URL, true)
		AcceptHeader := "application/json;q=1.0,text/plain;q=0.1"
		WebRequest.SetRequestHeader("Accept", AcceptHeader)
		WebRequest.SetRequestHeader("If-None-Match", lastETag)
		try {
		WebRequest.Send()
		TimeOut := WebRequest.WaitForResponse(5)
		} catch HttpErr {
			Return "WinHttp: " . HttpErr
		}
		
		if (TimeOut != "VARIANT_FALSE") { ;if NOT TimeOut
			RespHeaders := WebRequest.GetAllResponseHeaders()
			ContentType := RegExReplace(WebRequest.GetResponseHeader("Content-Type"), "i);\s+charset=utf-8", , , 1)
			lastETag := WebRequest.GetResponseHeader("etag")
			
			Switch WebRequest.Status {
				Case 200:
					Switch ContentType {
						Case "application/json":
							ReleasesRaw := WebRequest.ResponseText
							
							;Parse Json
							Releases := JSON.Load(ReleasesRaw)
							;FileAppend, % Json.dump(Releases), test.json
							NetChangeLog := ""
							
							if (WebRequest.GetResponseHeader("x-ratelimit-remaining") == 0) {
								NetChangeLog := "REQUEST LIMIT REACHED. Try again later.`n"
							}
							
							AboveZeroRelease := false
							For i, release in Releases
							{
								AboveZeroRelease := true
								ReleaseChangeLog := release.name
								ReleaseChangeLog .= StringPad("tag: " . release.tag_name, (WindowWidth - 5 - StrLen(release.name)), "L")
								release.body := RegExReplace(release.body, "\\r(\\n)*", "`n")
								bodyNoJson := RegExReplace(release.body, "\\r", "")		; Willy nilly wonky >:/
								bodyNoJson := RegExReplace(bodyNoJson, "\\", "")
								
								ReleaseBodyBlock := "  "
								if (release.prerelease == true) {
									ReleaseBodyBlock .= "(PRERELEASE)`n     "
								}
								releaseBody := StrSplit(bodyNoJson, "`n")
								For key, val in releaseBody
								{
									/*
									line := ""
									TextBlock := WordWrap(val, WindowWidth - 5)
									Loop, Parse, TextBlock, "`n", ""
									{
										line .= "`n     " . A_LoopField
									} 
									*/
									line := val . "`n" . "     "
									ReleaseBodyBlock .= line
								}
								ReleaseBodyBlock := RegExReplace(ReleaseBodyBlock, ")\s*$")
								
								ReleaseChangeLog .= "`n" . ReleaseBodyBlock
								NetChangeLog := NetChangeLog . "`n`n" . ReleaseChangeLog
							}
							if (NOT AboveZeroRelease) {
								NetChangeLog := "No releases yet!"
							}
						Default:
							NetChangeLog := "Unexpected Content-Type: " . ContentType . "`n" . WebRequest.ResponseText
					}
					NetChangeLog := Trim(NetChangeLog, "`r`n`t ")
				Case 304:
					;No New changelog, keep old one!
					Global ChangeLog
					Return ChangeLog
				Default:
					NetChangeLog := "HTTP Code: " . WebRequest.Status . "`n" . WebRequest.StatusText
			}
		} else {
			NetChangeLog := "http request timed out."
		}
	} else {
		NetChangeLog := "`n`nPress >Refresh< to get the ChangeLog."
	}
	Return NetChangeLog
}

AutoUpdater:
	ListLines, On
	AutoUpdater(ScriptVersion, GHUser, ScriptName, "version")
	Return

AutoUpdater(currentVersion, GitHubUser, repoName, versionControl, branch:="main") {
	/*
		AutoHotkey Version 1.1.30.00
		by mshall on AHK forums, Github.com/MattAHK
		free for use, adapted by Chaos_02
	*/	
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	URL := "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . branch . "/" . versionControl
	WebRequest.Open("GET", URL, false)
	try {
		WebRequest.Send()
		WebRequest.WaitForResponse(5)
	} catch HttpErr {
		Return "WinHttp: " . HttpErr
	}
	if NOT (ErrorLevel) {
		UpStreamVersion := Trim(WebRequest.ResponseText, "`r`n`t ")
		AUpdateStatus := versionCompare(currentVersion, UpStreamVersion)
	} else {
		AUpdateStatus := ErrorLevel
		ErrorLevel := 0
	}
	Switch AUpdateStatus {
		Case 1:
			
			
			MsgBox, 1, % (repoName . " Updater"), % "Your current version is: " . currentVersion . ".`nLatest is: " . UpStreamVersion . ".`nPress OK to download."
			IfMsgBox, OK
			{
				if (NOT A_IsCompiled) {
					DownloadURL := "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . branch . "/" . repoName . ".ahk"
					WebRequest.Open("GET", DownloadURL, false)
					try {
						WebRequest.Send()
						WebRequest.WaitForResponse(10)
					} catch HttpErr {
						MsgBox, % "An error has occured while downloading.`nCode: " . ErrorLevel
					}

					if (WebRequest.Status == 200) {
						FileAppend, % WebRequest.ResponseText, ".tmp-" . A_ScriptName
						;Overwrite A_ScriptFullPath
						Run, A_ScriptFullPath
						ExitApp
					} else {
						MsgBox, % "An error has occured while downloading.`nHTTP code: " . WebRequest.Status
					}
				} else {
					DownloadURL := "https://api.github.com/repos/" . GitHubUser . "/" . repoName . "/releases?page=1&per_page=" . 1

					WebRequest.Open("GET", DownloadURL, true)
					AcceptHeader := "application/json;q=1.0,text/plain;q=0.1"
					WebRequest.SetRequestHeader("Accept", AcceptHeader)
					try {
					WebRequest.Send()
					TimeOut := WebRequest.WaitForResponse(5)
					} catch HttpErr {
						Return "WinHttp: " . HttpErr
					}
					switch WebRequest.Status {
						case 200:
							Release := JSON.Load(WebRequest.ResponseText)

							DownloadURL := Release[1].assets[1].url
							WebRequest.Open("GET", DownloadURL, true)
							AcceptHeader := "application/octet-stream;q=1.0,text/plain;q=0.1"
							WebRequest.SetRequestHeader("Accept", AcceptHeader)
							WebRequest.Send()
							TimeOut := WebRequest.WaitForResponse(10)
							if (TimeOut != "VARIANT_FALSE") {
								while (WebRequest.Status == 302) { ;redirect
									DownloadURL := WebRequest.GetResponseHeader("location")
									WebRequest.Open("GET", DownloadURL, true)
									AcceptHeader := "application/octet-stream;q=1.0,		text/plain;q=0.1"
									WebRequest.SetRequestHeader("Accept", AcceptHeader)
									WebRequest.Send()
									TimeOut := WebRequest.WaitForResponse(10)
								}

								if (WebRequest.Status == 200) {
									OutFile := FileOpen((A_ScriptDir . "\.tmp-" . Release[1].assets[1].name), "w-w", "CP437")
									ByteArr := WebRequest.ResponseBody
									Loop % ByteArr.MaxIndex() + 1
									{
										OutFile.WriteUChar(ByteArr[A_Index - 1])
									}
									OutFile.Close()
									/* Instead -->
										DLLCall("OleAut32\SafeArrayAccessData", "Ptr", ComObjValue(WebRequest.ResponseBody), "Ptr*", Data)
										OutFile.RawWrite(Data, WebRequest.ResponseBody.MaxIndex() -1)
										DllCall("OleAut32\SafeArrayUnaccessData", "Ptr", ComObjValue(ResponseBody))
									*/

									FileDelete, A_ScriptFullPath
									FileMove, (A_ScriptDir . "\.tmp-" . Release[1].assets[1].name), (A_ScriptDir . "\" . Release[1].assets[1].name)
									Run, % (A_ScriptDir . "\" . Release[1].assets[1].name)
									ExitApp
								} else {
									MsgBox, % "An error has occured while downloading.`nHTTP code: " . WebRequest.Status
								}
							} else {
								MsgBox, % "An error has occured while downloading.`nHTTP timeout."
							}
						Default:
							MsgBox, % "An error has occured while downloading.`nHTTP code: " . WebRequest.Status
					}
				}
			}
		Case false:
			MsgBox, % "Already up-to-date!"
		Default:
			MsgBox, % "Error while obtaining version!"
	}
	Return
}


;; Libraries

/**
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */
/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	*/
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
		ListLines, Off
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false
			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"
			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0
			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)
				holder := stack[1]
				is_array := holder.IsArray
				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value
				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"
				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						ObjInsertAt(stack, 1, value)
						if (this.keys)
							this.keys[value] := []
					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")
								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}
							if (!i)
								this.ParseError("'", text, pos)
							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")
							pos := i ; update pos
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))
								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}
							if (is_key) {
								key := value, next := ":"
								continue
							}
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)
							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)
							pos += i-1
						}
						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else
					is_array? key := ObjPush(holder, value) : holder[key] := value
					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			} ; while ( ... )
			ListLines, On
			return this.rev ? this.Walk(root, "") : root[""]
		}
		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)
			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}
		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			return this.rev.Call(holder, key, value)
		}
	}
	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			ListLines, Off
			this.rep := IsObject(replacer) ? replacer : ""
			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)
				this.indent := "`n"
			}
			ListLines, On
			return this.Str({"": value}, "")
		}
		Str(holder, key)
		{
			value := holder[key]
			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)
			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}
					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}). 
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}
					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent
							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent
								str .= this.Quote(k) . colon . v . ","
							}
						}
					}
					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}
					if (this.gap)
						this.indent := stepback
					return is_array ? "[" . str . "]" : "{" . str . "}"
				}
			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}
		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot
			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")
				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}
			return quot . string . quot
		}
	}
	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. Returning blank("") or 0 won't work since these
	 *     can't be distnguished from actual JSON values. This leaves us with objects.
	 *     Replacer() - the caller may return a non-serializable AHK objects such as
	 *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
	 *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
	 *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
	 *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}
	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}

FileGetInfo(lptstrFilename) {
	List := "Comments InternalName ProductName CompanyName LegalCopyright ProductVersion"
		. " FileDescription LegalTrademarks PrivateBuild FileVersion OriginalFilename SpecialBuild"
	dwLen := DllCall("Version.dll\GetFileVersionInfoSize", "Str", lptstrFilename, "Ptr", 0)
	dwLen := VarSetCapacity( lpData, dwLen + A_PtrSize)
	DllCall("Version.dll\GetFileVersionInfo", "Str", lptstrFilename, "UInt", 0, "UInt", dwLen, "Ptr", &lpData)
	lplpBuffer := ""
	puLen := ""
	DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\VarFileInfo\Translation", "PtrP", lplpBuffer, "PtrP", puLen )
	sLangCP := Format("{:04X}{:04X}", NumGet(lplpBuffer+0, "UShort"), NumGet(lplpBuffer+2, "UShort"))
	i := {}			;replace with \/
	; i := Map()	; for AHK>v2
	Loop, Parse, % List, %A_Space%
	{
		DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\StringFileInfo\" sLangCp "\" A_LoopField, "PtrP", lplpBuffer, "PtrP", puLen )
		? i[A_LoopField] := StrGet(lplpBuffer, puLen) : ""
	}
	return i
}