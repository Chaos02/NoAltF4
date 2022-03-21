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

ScriptVersion := "0.9.0"
GHUser := "Chaos02"
DefaultAddKeyWords := "Key, words, here"
SplitPath, A_ScriptFullPath, , , , ScriptName
ConfigFile := A_AppData . "\" . ScriptName . ".ini"
AutoStartFile := A_StartUp . "\" . ScriptName . ".lnk"

InitialRun := false
Notified := false
InclusionKeywords := Array()
AdditionalKeywords := Array()
SteamPaths := Array()

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

SetTimer, main, 1000

Gosub SetUpdateStatusIcon

while (1>0) {
	; NOP
	sleep, 2000
}
MsgBox, ERROR: We were not supposed to get to this point....`nScript will exit.
ExitApp


main:
	WinGet, WinPath, ProcessPath, A
	HasWord := false
	For i, KeyWord in InclusionKeywords
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
	;Pause
	Return

GuiCreator:
	if NOT (MenuCreated) {
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
		
		ChangeLog := GetChangeLog(GHUser, ScriptName, 2)
		SetTimer, SetUpdateStatusIcon, % (1000 * 60 * 30) ; Run every 30 mins
		MenuCreated := true
	}
	
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
		Temp := Array()
		FoundPos := InStr(A_LoopField, "" . "path" . "", true, 1)
		if (FoundPos != 0) {
			Temp := StrSplit(A_LoopField, " `t", "" . " `t", 2)
			SteamPaths.Push(Temp[2])
			InclusionKeywords.Push(Temp[2])
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
	for Counter, Entry in strArray
		Str := Str . ", " . Entry
	return Str
}

ReadLine(StringVar, LineNumber)
{
	StringPerLine := Array()
	Loop, Parse, StringVar, "`n`r"
	{
		StringPerLine[A_Index] := A_LoopField
	}
	Return StringPerLine[LineNumber]
}

ReadMDHTML(HtmlStr, ContentTags := ["h1", "h2", "h3", "h4", "h5", "h6", "a", "p"])
{
	;TODO: each <h1/> tag that has an <a/> tag is headline. there can be multiple <p/> per release.
	;Extracts the content from an HTML string
	j := 1
	Content := Array()
	while j <= StrLen(HtmlStr)
	{
		if (SubStr(HtmlStr, j, 1) == "<") {
			HasContent := false
			TagType :=
			For j2, Tag in ContentTags
			{
				HasContent := HasContent || InStr(SubStr(HtmlStr, j+1, 2), Tag, false)
				if HasWord {
					TagType := Tag
					break
				}
			}
			if HasContent {
				;Find next closing tag
				while (SubStr(HtmlStr, j, 1) != ">") ; should always be a '">'???
				{
					j++
				}
				;Read Content of Tag.
				while NOT InStr(SubStr(HtmlStr, j+1, 5), "</" . TagType . ">")
				{
					Content.Push(SubStr(HtmlStr, j, 1))
				}
			}
		}
	}
	;RegExMatch(HtmlStr, "iO)(?<=\<)[^ 	]+", Tag) ; Creates a Match object in Tag
	
	Return Content
}

ShowStartup:
	Run, % ("properties " . AutoStartFile)
	Return

CheckUpdate(localVersion, GitHubUser, repoName, versionControl)
{
	; Seperate thread?
	Global MenuCreated
	if NOT (MenuCreated) {
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		WebRequest.Open("GET", "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . "/" . versionControl, true)
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
		Case true:
		Menu, OptionMenuBar, Icon, Updater, Shell32.dll, 147, 16 ;Update icon
		Menu, Tray, Tip, % (ScriptName . " update available")
		if NOT (Notified) {
			TrayTip, % (ScriptName . " Updater"), An Update is available!`nDownload it through the Updater Gui!, 5
			Notified := true
		}
		Case 0:
			Menu, Tray, Tip, % ScriptName
			Menu, OptionMenuBar, Icon, Updater, ; Or Update circle icon
		Default:
			Menu, Tray, Tip, % (ScriptName . " Updater ERROR: " . UpdateStatus)
			Menu, OptionMenuBar, Icon, Updater, Shell32.dll, 128, 16 ;RedCross icon
			Menu, OptionMenuBar, Rename, 2&, % ("Updater error: " . UpdateStatus)
			; Display ErrorLevel somehow?
	}
	Return

ShowUpdater:
	Gui, Updater:Show, Center AutoSize, % (ScriptName . "updater")
	
	; TODO: Fix Parenting...?
	
	Gui, Updater:+OwnDialogs
	Gui, Options:+OwnerUpdater
	Return

UpdaterGuiClose:
	Gui, Options:-Owner
	Gui, Updater:-OwnDialogs
	Gui, Updater:Hide
	Return

UpdateRefresh:
	Gosub SetUpdateStatusIcon
	ChangeLog := GetChangeLog(GHUser, ScriptName, 2)
	GuiControl, , ChangeLog, % ChangeLog
	Return

GetChangeLog(GitHubUser, repoName, ChangeLogDepth) {
	; DEBUG:
		repoName := "SubFolderLoader"
	
	Global MenuCreated
	if (MenuCreated) {
		WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		
		WebRequest.Open("GET", "https://github.com/" . GitHubUser . "/" . repoName . "/releases", true)
		WebRequest.Send()
		
		WebRequest.WaitForResponse()
		ReleasesRaw := WebRequest.ResponseText
		
		ReleasesRaw := StrReplace(ReleasesRaw, "<h1>", "ª") ; one of "¢¤¥¦§©ª«®µ¶"
		ReleaseHeadlines := Array()
		ReleaseNotes := Array()
		Loop, Parse, ReleasesRaw, "`n`r"
		{
			IsInStr := InStr(A_LoopField, "ª", true, 1)
			if (IsInStr) {
				ReleaseHeadlines[A_Index] := ReadMDHTML(ReadLine(ReleasesRaw, A_Index), ["h1"])
				ReleaseNotes[A_Index] := "`t" . ReadMDHTML(ReadLine(ReleasesRaw, A_Index + 1), ["p"])
			}
		}
		NetChangeLog :=
		;i := ReleaseHeadlines.Length()
		;While (i--)
		For j in ReleaseHeadlines
		{
			if NOT (j > ChangeLogDepth) {
				NetChangeLog := NetChangeLog . "`n" . ReleaseHeadlines[j]
				ReleaseNotes[j] := StrReplace(ReleaseNotes[j], "`n", "`n`t")
				NetChangeLog := NetChangeLog . "`n`t" . ReleaseNotes[j]
			} else {
				break
			}
		}
		; NetChangeLog := ReleasesRaw
	} else {
		NetChangeLog := "Press Refresh to get the ChangeLog."
	}
	Return NetChangeLog
}

AutoUpdater:
	AutoUpdater(GHUser, ScriptName, "version")
	Return

AutoUpdater(GitHubUser, repoName, versionControl)
{
	/*
		AutoHotkey Version 1.1.30.00
		by mshall on AHK forums, Github.com/MattAHK
		free for use, adapted by Chaos_02
	*/
	
	url := "https://github.com/" . GitHubUser . "/" . repoName . "/releases/latest/download/"
	
	WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WebRequest.Open("GET", "https://raw.githubusercontent.com/" . GitHubUser . "/" . repoName . versionControl, true)
	WebRequest.Send()
	
	WebRequest.WaitForResponse()
	UpStreamVersion := WebRequest.ResponseText
	if (Version != UpStreamVersion) {
		MsgBox, 1, % (repoName . " Updater"), Your current version is %Version%.`nLatest is %UpStreamVersion%.`nPress OK to download.
		IfMsgBox, OK
		{
			URLDownloadToFile, *0 %url%, A_ScriptPath . "\.tmp-" . A_ScripName
			if (ErrorLevel == 0) {
			
			} else {
				MsgBox, 1, An error has occured while downloading.`nCode: %ErrorLevel%
			}
		}
	}
	Return
}
