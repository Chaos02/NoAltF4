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




if (A_AHKVersion < "1.1.13") {
	Gui, Version:New, AlwaysOnTop -MinimizeBox -Resize, ERROR
	Gui, Version:Add, Link,, Error. Please download AHK > v1.1.13! `n (<a href="https://www.autohotkey.com/download/ahk-install.exe">Download</a>)
	Gui, Version:Show
	Return

	VersionGuiClose:
		ExitApp
}

ScriptVersion := "0.9.0"
GHUser := "Chaos02"
DefaultAddKeyWords := "Key, words, here"
SplitPath, A_ScriptFullPath, , , , ScriptName
ConfigFile := A_AppData . "\" . ScriptName . ".ini"
AutoStartFile := A_StartUp . "\" . ScriptName . ".lnk"

InitialRun := false
Notified := false
PollTime := ""
InclusionKeywords := Array()
AdditionalKeywords := Array()
SteamPaths := Array()

	Hotkey, ^!P, Unpause
	/*
	FileDelete, % (A_AppData . "\" . ScriptName . ".txt")
	NestObject2 := {"Haha test lul": "drölf", "Hilfe?":"maybe?"}
	NestObject1 := Object("Property1", 5, "prop2", 10, "NestObject2", NestObject2)
	TestObject := {"Value": false, "NestObj", NestObject1, "Keywords", DefaultKeywords )
	FileAppend, % ExploreObj(TestObject) . "`n`n`nOwn:`n", % (A_AppData . "\" . ScriptName . ".txt")
	FileAppend, % ObjectToString(TestObject), % (A_AppData . "\" . ScriptName . ".txt")
	*/

Gosub ConfigRead

MenuCreated := false
Gosub GuiCreator

if (ShowSettings || NOT FileExist(AutoStartFile)) {
	gosub Configure
}

; Self-schedule autostart:
FileCreateShortcut, % A_ScriptFullPath, % AutoStartFile, , , "Captures Alt+F4 from Programs with keywords in their path."

LibFilePath := "" . SteamPath . "\steamapps\libraryfolders.vdf" . ""
; LibFilePath := "" . "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf" . ""


InclusionKeywords.Push(DefaultKeywords*)
if (GetFromSteam) {
	Gosub ReadSteamLibs
}

Hotkey, $<!F4, HahaNo, Off
Hotkey, $<^>!F4, DoIt, On

;SetTimer, main, 1000

Gosub SetUpdateStatusIcon

ListLines, Off
while (1>0) {
	; NOP
	sleep, 2000
}
MsgBox, ERROR: We were not supposed to get to this point....`nScript will exit.
ExitApp


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
	ListLines, On
	if HasWord {
		Hotkey, <!F4, On
		SetTimer, main, 5000
	} else {
		Hotkey, <!F4, Off
		SetTimer, main, 1000
	}
	Return

GuiCreator:
	if NOT (MenuCreated) {
		ListLines, Off
		;Menu, TrayMenu, NoStandard ; Remove AHK Tray Menu entries
		Menu, Tray, Add, Configure
		Menu, Tray, Default, Configure
		; Menu, Tray, Color, 333333 ; Background Color of Tray Menu (goes away after hover >:/ )
		Menu, Tray, Click, 2 ; Doubleclick to activate default menu item
		Menu, Tray, Tip, % ScriptName
		Menu, Tray, Icon, Shell32.dll, 105, 1 ;keys icon
		
		; FileGetVersion, ScriptVersion, A_ScriptFullPath
		
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
	Gui, Updater:Font, , "Lucida Console"
	Gui, Updater:New, +Border +Caption +DPIScale -Resize, % (ScriptName . " updater")
	Gui, Updater:Add, GroupBox, x2 y0 w380 h140, Changelog:
	Gui, Updater:Add, Edit, x12 y19 r8 vChangeLog w360 +ReadOnly +Wrap, % ChangeLog
	Gui, Updater:Add, Button, x100 y150 w80 h20 gUpdateRefresh, Refresh
	Gui, Updater:Add, Button, x200 y150 w80 h20 gAutoUpdater, Update
	Gui, Updater:Add, Button, x300 y150 w80 h20 gUpdaterGuiClose, Close
	
	Gui, Options:New, +Border +Caption +DPIScale -Resize, % (ScriptName . " " . "options")
	Gui, Options:Add, GroupBox, x2 y0 w380 h90, Keywords
	Gui, Options:Add, Text, x12 y14 r1 cGray, % ("Built-in: " . ArrayJoin(DefaultKeywords))
	Gui, Options:Add, Text, x12 y28 r1 cGray, % ("Steam: " . ArrayJoin(SteamPaths))
	Gui, Options:Add, Edit, x12 y44 w360 h20 -Wrap -Multi -WantReturn gEditChange vKeywordsRaw, % KeywordsRaw
	Gui, Options:Add, CheckBox, x14 y69 r1 vGetFromSteam Checked%GetFromSteam%, Import Libraries from Steam?
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
	AdditionalKeywords.Delete("Key")
	AdditionalKeywords.Delete("words")
	AdditionalKeywords.Delete("here")
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
	Gui, Options:Show, Center AutoSize, % (ScriptName . "options")
	Loop 3 {
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
	LibFileContent := SteamLibFile.Read()
	Loop, Parse, % LibFileContent, "`n`r", " `t"
	{
		ListLines, Off
		PathRegex := "O)(?<=""path""\t\t)"".+"""
		RegExMatch(A_LoopField, PathRegex, FoundPos)
		Path := RegExReplace(FoundPos.Value, "\\", "\")
		SteamPaths.Push(Path)
		InclusionKeywords.Push(Path)
	}
	ListLines, On
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
	MsgBox, No.
	Return

DoIt:
	SendInput !{F4}
	Return

ArrayJoin( strArray ) {
	Str := strArray[1]
	for Counter, Entry in strArray
		Str := Str . ", " . Entry
	return Str
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
	Loop, Parse, StringVar, "`n`r"
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
	Run, % ("properties " . AutoStartFile)
	Return

CheckUpdate(localVersion, GitHubUser, repoName, versionControl, branch:="main")
{
	; Seperate thread?
	Global MenuCreated
	if (MenuCreated) {
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		URL := "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . branch . "/"versionControl
		WebRequest.Open("GET", URL, true)
		WebRequest.Send()
		WebRequest.WaitForResponse()
		UpStreamVersion := WebRequest.ResponseText
		if NOT (ErrorLevel) {
			Return (localVersion != UpStreamVersion)
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
		Menu, OptionMenuBar, Icon, Updater, Shell32.dll, 147, 16 ;Update icon
		Menu, Tray, Tip, % (ScriptName . "`nUpdate available!")
		if NOT (Notified) {
			TrayTip, % (ScriptName . " Updater"), An Update is available!`nDownload it through the Updater Gui!, 5
			Notified := true
		}
		Case false:
			Menu, Tray, Tip, % ScriptName
			Menu, OptionMenuBar, Icon, Updater, ; Or Update circle icon
		Default:
			Menu, Tray, Tip, % (ScriptName . "`nUpdater ERROR: " . UpdateStatus)
			Menu, OptionMenuBar, Icon, Updater, Shell32.dll, 128, 16 ;RedCross icon
			Menu, OptionMenuBar, Rename, 2&, % ("Updater (error: " . UpdateStatus . ")")
			; Display ErrorLevel somehow?
	}
	Return

ShowUpdater:
	Gui, Updater:Show, Center AutoSize, % (ScriptName . "updater")
	
	; TODO: Fix Parenting...?
	Gosub UpdateRefresh
	
	Gui, Updater:+OwnDialogs
	Gui, Options:+OwnerUpdater
	Return

UpdaterGuiClose:
	Gui, Options:-Owner
	Gui, Updater:-OwnDialogs
	Gui, Updater:Hide
	Return

UpdateRefresh:
	;SetCursor("WAIT")	;mostly gets stuck.... >:/
	Gosub SetUpdateStatusIcon
	ChangeLog := GetChangeLog(GHUser, ScriptName, 3)
	GuiControl, , ChangeLog, % ChangeLog
	;SetCursor("ARROW")
	Return

SetCursor(CursorName := "ARROW", ReplacedCursor := "ARROW") {
	;Replace ReplacedCursor with CursorName
	; https://www.autohotkey.com/board/topic/32608-changing-the-system-cursor/
	
	StringUpper, CursorName, CursorName
	StringUpper, ReplacedCursor, ReplacedCursor
	
	Global Replacor
	Global Replaced
	
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
	
	CursorHandle := DllCall( "LoadCursor", Uint,0, Int, Replacor )
	DllCall( "SetSystemCursor", Uint, CursorHandle, Int, Replaced )
	Return ErrorLevel
	;Reload system cursors (Restore)
	;SPI_SETCURSORS := 0x57
	;DllCall( "SystemParametersInfo", UInt,SPI_SETCURSORS, UInt,0, UInt,0, UInt,0 )
}

GetChangeLog(GitHubUser, repoName, ChangeLogDepth:=1, Init:=false) {
	Global PollTime
	if (Init) {
		;CreateFormData(ReleasesRaw, ReleasesHeader, requestQuery)
		URL := "https://api.github.com/repos/" . GitHubUser . "/" . repoName . "/releases?page=1&per_page=" . ChangeLogDepth
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		; true for asynchronously, false for synchronously. Async lets Send wait for response
		WebRequest.Open("GET", URL, false)
		WebRequest.SetRequestHeader("Accept", "application/json;q=1.0,text/plain;q=0.1")
		WebRequest.SetRequestHeader("If-Modified-Since", PollTime)
		WebRequest.Send()
		
		TimeOut := WebRequest.WaitForResponse(5)
		
		if (TimeOut != "VARIANT_FALSE") { ;if NOT TimeOut
			RespHeaders := WebRequest.GetAllResponseHeaders()
			ContentType := RegExReplace(WebRequest.GetResponseHeader("Content-Type"), "i);\s+charset=utf-8", , , 1)
			PollTime := WebRequest.GetResponseHeader("date")
			ChangeLogRateUsed := WebRequest.GetResponseHeader("x-ratelimit-remaining")
			
			Switch ContentType {
				Case "application/json":
					ReleasesRaw := WebRequest.ResponseText
					
					;Parse Json
					Releases := JSON.Load(ReleasesRaw)
					NetChangeLog := ""
					
					if (WebRequest.GetResponseHeader("x-ratelimit-remaining") == 0) {
						NetChangeLog := "REQUEST LIMIT REACHED. Try again later.`n"
					}
					
					For i, release in Releases
					{
						ReleaseChangeLog := release.name
						ReleaseChangeLog .= StringPad(release.tag_name, (85 - StrLen(release.name)), "L")
						release.body := RegExReplace(release.body, "\R+", "`n")
						
						ReleaseBodyBlock := "   "
						For key, val in ReadLine(release.body, "*")
						{
							ReleaseBodyBlock .= val . "`n" . "   "
						}
						ReleaseBodyBlock := RegExReplace(ReleaseBodyBlock, ")\s*$")
						
						ReleaseChangeLog .= "`n" . ReleaseBodyBlock
						NetChangeLog := NetChangeLog . "`n`n" . ReleaseChangeLog
					}
				Default:
					NetChangeLog := "Unexpected Content-Type: " . ContentType . "`n" . WebRequest.ResponseText
			}
			NetChangeLog := Trim(NetChangeLog, "`r`n`t ")
		} else {
			NetChangeLog := "http request timed out."
		}
	} else {
		NetChangeLog := "`n`nPress >Refresh< to get the ChangeLog."
	}
	Return NetChangeLog
}

AutoUpdater:
	AutoUpdater(ScriptVersion, GHUser, ScriptName, "version")
	Return

AutoUpdater(currentVersion, GitHubUser, repoName, versionControl, branch:="main")
{
	/*
		AutoHotkey Version 1.1.30.00
		by mshall on AHK forums, Github.com/MattAHK
		free for use, adapted by Chaos_02
		TODO: Get latest release!
	*/
	
	url := "https://github.com/" . GitHubUser . "/" . repoName . "/releases/latest/download/"
	
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	URL := "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . branch . "/"versionControl
	WebRequest.Open("GET", URL, true)
	WebRequest.Send()
	
	WebRequest.WaitForResponse()
	UpStreamVersion := WebRequest.ResponseText
	if (currentVersion != UpStreamVersion) {
		MsgBox, 1, % (repoName . " Updater"), % "Your current version is: " . currentVersion . ".`nLatest is: " . Trim(UpStreamVersion, "`r`n`t ") . ".`nPress OK to download."
		IfMsgBox, OK
		{
			URLDownloadToFile, *0 %URL%, A_ScriptPath . "\.tmp-" . A_ScripName
			if (ErrorLevel == 0) {
				;Overwrite A_ScriptFullPath
				Run, A_ScriptFullPath
				ExitApp
			} else {
				MsgBox, % "An error has occured while downloading.`nCode: " . ErrorLevel
			}
		}
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
