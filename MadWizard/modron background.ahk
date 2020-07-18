SetWorkingDir, %A_ScriptDir%
SetMouseDelay, 30
CoordMode, Pixel, Screen
CoordMode, ToolTip, Screen

;VARIABLES BASED NEEDED TO BE CHANGED

;if using speed Pots, manually specify your Briv farming time in minutes
Global overrideBrivTime := 1.5
Global speedBrivTime := 0.5
Global ScriptSpeed := 1, DefaultSleep := 50


Global AreaLow := 326 ;z26 to z29 has portals, z41 & z16 has a portal also


;VARIABLES NOT NEEDED TO BE CHANGED
;   If you make no major changes to the script
Global RunCount := 0, FailedCount := 0
Global dtStartTime := "00:00:00", dtLastRunTime := "00:00:00"
Global crashes := 0

LoadTooltip()

;click while keys are held down
$F1::
    While GetKeyState("F1", "P") {
        MouseClick
        Sleep 0
    }
return

;start the Mad Wizard gem runs
$F2::
    Menu, Tray, Icon, %SystemRoot%\System32\setupapi.dll, 10
    dtStartTime := A_Now
    loop {
        dtLastRunTime := A_Now
        WaitForResults()
    }
return

;click until Reload or Exiting the app
$F3::
    Menu, Tray, Icon, %SystemRoot%\System32\setupapi.dll, 10
    loop {
        MouseClick
        Sleep 0
    }
return

;Reload the script
$F9::
    if RunCount > 0
        DataOut()
    Reload
return

;kills the script
$F10::ExitApp

$`::Pause

#c::
    WinGetPos, X, Y, Width, Height, A
    WinMove, A,, (Max(Min(Floor((X + (Width / 2)) / A_ScreenWidth), 1), 0) * A_ScreenWidth) + ((A_ScreenWidth - Width) / 2), (A_ScreenHeight - Height) / 2
return


SafetyCheck(Skip := False) {
    While(Not WinExist("ahk_exe IdleDragons.exe")) {
        Run, "C:\Program Files (x86)\Steam\steamapps\common\IdleChampions\IdleDragons.exe"
        Sleep 30000
        DirectedInput("2345678")
        crashes++
    }
    if Not Skip {
        ;WinActivate, ahk_exe IdleDragons.exe
    }
}

DirectedInput(s) {
	SafetyCheck(True)
	ControlFocus,, ahk_exe IdleDragons.exe
	ControlSend, ahk_parent, {Blind}%s%, ahk_exe IdleDragons.exe
	Sleep, %ScriptSpeed%
}

FindInterfaceCue(filename, ByRef i, ByRef j, time = 0) {
	SafetyCheck()
	WinGetPos, x, y, width, height, ahk_exe IdleDragons.exe
	start := A_TickCount
	Loop {
		ImageSearch, outx, outy, x, y, % x + width, % y + height, *15 *Trans0x00FF00 %filename%
		If (ErrorLevel = 0) {
			i := outx - x, j := outy - y
			Return True
		}
		If ((A_TickCount - start)/1000 >= time) {
			Return False
		}
		Sleep, %ScriptSpeed%
	}
}

ResetStep(filename, k, l, timeToRun := 0, bool := True) {
    If FindInterfaceCue(filename, i, j, timeToRun) {
		SafetyCheck()
		ControlClick, % "x" i + k " y" j + l, ahk_exe IdleDragons.exe
	}
	Else If (bool) {
		Reload
	}
}

WaitForResults() {  

    workingArea := "areas\" . AreaLow . "working.PNG" ;meant to stop on areaNum
    completeArea := "areas\" . AreaLow . "complete.PNG" ;meant if skip areaNum
    brivStacked := false
    loop {
        ;simple click incase of fire
        SafetyCheck()
        ;MouseClick, L, 650, 450, 2
        
        if FindInterfaceCue("areas\1.png", i, j) {
            RunCount += 1
            dtLastRunTime := A_Now
            Sleep 5000
            DirectedInput("12345678")
            brivStacked := false
            Sleep 15000
        }

        if (Not brivStacked And (FindInterfaceCue(workingArea, i, j) Or FindInterfaceCue(completeArea, i, j))) {
            BuildBrivStacks()
            brivStacked := true
        }

        if FindInterfaceCue("runAdventure\offlineOkay.png", i, j) {
            SafetyCheck()
            ControlClick, % "x" i + 5 " y" j + 5, ahk_exe IdleDragons.exe
            Sleep 50
        }
            
        if FindInterfaceCue("runAdventure\progress.png", i, j) {
            DirectedInput("g")
        }

        currentRunTime := round(MinuteTimeDiff(dtLastRunTime, A_Now), 2)
        LoopedTooltip(currentRunTime)
    }
}

BuildBrivStacks() {
    DirectedInput("w")
    DirectedInput("g")
    Sleep 5
    DirectedInput("w")
    Sleep 5
    DirectedInput("w")
    if (FindInterfaceCue("runAdventure\speedUsed.png", i, j, 1) And speedBrivTime > 0)
        Sleep % speedBrivTime * 60 * 1000 * 1.05
    else
        Sleep % overrideBrivTime * 60 * 1000 * 1.05
    DirectedInput("q")
    DirectedInput("g")
    Sleep 5000
    DirectedInput("q")
}

DataOut() {
    FormatTime, currentDateTime,, MM/dd/yyyy HH:mm:ss
    dtNow := A_Now
    toWallRunTime := DateTimeDiff(dtStartTime, dtLastRunTime)
    lastRunTime := DateTimeDiff(dtLastRunTime, dtNow)
    totBosses := Floor(AreaLow / 5) * RunCount
    currentPatron := NpVariant ? "NP" : MirtVariant ? "Mirt" : VajraVariant ? "Vajra" : StrahdVariant ? "Strahd" : "How?"
    areaStopped = 0 ;InputBox, areaStopped, Area Stopped, Generaly stop on areas ending in`nz1 thru z4`nz6 thru z9
    ;meant for Google Sheets/Excel/Open Office
    FileAppend,%currentDateTime%`t%AreaLow%`t%toWallRunTime%`t%lastRunTime%`t%RunCount%`t%totBosses%`t%currentPatron%`t%FailedCount%`t%areaStopped%`n, MadWizard-Bosses.txt
}

{ ;time HELPERS
    ;return String HH:mm:ss of the timespan
    DateTimeDiff(dtStart, dtEnd) {
        dtResult := dtEnd
        
        EnvSub, dtResult, dtStart, Seconds
        
        return TimeResult(dtResult)
    }
    
    ;might use later
    TimeSpanAverage(ts1, nCount) {
        time_parts1 := StrSplit(ts1, ":")
        t1_seconds := (((time_parts1[1] * 60) + time_parts1[2]) * 60) + time_parts1[3]
        if (!nCount) {
            return "00:00:00"
        }
        return TimeResult(t1_seconds / nCount)
    }
    
    TimeResult(dtResult) {
        nSeconds := Floor(Mod(dtResult, 60))
        nMinutes := Floor(dtResult / 60)
        nHours := Floor(nMinutes / 60)
        nMinutes := Mod(nMinutes, 60)
        
        sResult := (StrLen(nHours) = 1 ? "0" : "") nHours ":" (StrLen(nMinutes) = 1 ? "0" : "") nMinutes ":" (StrLen(nSeconds) = 1 ? "0" : "") nSeconds
        
        return sResult
    }
    
    MinuteTimeDiff(dtStart, dtEnd) {
        dtResult := dtEnd
        EnvSub, dtResult, dtStart, Seconds
        nSeconds := Floor(Mod(dtResult, 60))
        nMinutes := Floor(dtResult / 60)
        nHours := Floor(nMinutes / 60)
        nMinutes := Mod(nMinutes, 60)
        
        return (nMinutes + (nHours * 60) + (nSeconds / 60))
    }
}

{ ;tooltips
    LoadTooltip() {
        ToolTip, % "Shortcuts`nF2: Run MW`nF9: Reload`nF10: Kill the script`nThere are others", 50, 250, 1
        SetTimer, RemoveToolTip, -5000
        return
    }
    LoopedTooltip(currentRunTime) {
        WinGetPos, x, y, width, height, ahk_exe IdleDragons.exe
        ToolTip, % "Resets: " runCount "`nCrashes: " crashes "`nMins since start: " currentRunTime, % x + 50, % y + 200, 2
        SetTimer, RemoveToolTip, -1000
        return
    }
    RemoveToolTip:
        ToolTip
    return
}