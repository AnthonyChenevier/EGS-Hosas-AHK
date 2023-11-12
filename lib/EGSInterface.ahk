#Requires AutoHotkey v2.0
#include "EGSControlMap.ahk"
#include "HB_Vector.ahk"


; EGSControlMap 1
; For more info on what to put in for keys, visit: https://www.autohotkey.com/docs/KeyList.htm
cMap1 := new EGSControlMap()
cMap1.Axes.Yaw.AxisID := "R"
cMap1.Axes.Yaw.Sensitivity := 0.5
cMap1.Axes.Yaw.Deadzone := 20
   
cMap1.Axes.Pitch.AxisID := "Y"
cMap1.Axes.Pitch.Sensitivity := 0.2
cMap1.Axes.Pitch.Deadzone := 15

cMap1.Axes.Roll.AxisID := "X"
cMap1.Axes.Roll.Sensitivity := 0.2
cMap1.Axes.Roll.Deadzone := 15
cMap1.Axes.Roll.AxisKeys := { pos:"e", neg:"q" }
cMap1.Axes.Roll.SendModulationTime := 50    

cMap1.Axes.Throttle.AxisID := "Z"
cMap1.Axes.Throttle.Deadzone := 30 
cMap1.Axes.Throttle.Sensitivity := 1
cMap1.Axes.Throttle.AxisKeys := { pos: "w", neg:"s" }
cMap1.Axes.Throttle.SendModulationTime := 50    
; These adjust how long the keypress pulse interval is for analog 
;conversions of Yaw and Thrust. The key will be pressed down a 
;fraction of this time depending on analog input      
cMap1.Axes.Throttle.MinSendDurationRatio := 0.40
   
cMap1.Hat.X := { pos:"d", neg:"a" }                                
cMap1.Hat.Y := { pos:"space", neg:"c" }

cMap1.Buttons.Joy1 := "LButton"
cMap1.Buttons.Joy2 := "o"
cMap1.Buttons.Joy3 := "1"
cMap1.Buttons.Joy4 := "2"
cMap1.Buttons.Joy5 := "3"
cMap1.Buttons.Joy6 := "4"
cMap1.Buttons.Joy7 := "5"
cMap1.Buttons.Joy8 := "6"


; EGSControlMap 2  
; For more info on what to put in for keys, 
; visit: https://www.autohotkey.com/docs/KeyList.htm
; Profile 2 is set up to switch roll and yaw (leaning stick side
; to side turns instead of rolls) and does not invert the joystick
cMap2 := new EGSControlMap()
cMap2.Axes.Yaw.AxisID := "X"
cMap2.Axes.Yaw.Sensitivity := 0.2
cMap2.Axes.Yaw.Deadzone := 15

cMap2.Axes.Pitch.AxisID := "Y"
cMap2.Axes.Pitch.Sensitivity := 0.2
cMap2.Axes.Pitch.Deadzone := 15

cMap2.Axes.Roll.AxisID := "R"
cMap2.Axes.Roll.Sensitivity := 0.5
cMap2.Axes.Roll.Deadzone := 20
cMap2.Axes.Roll.AxisKeys := { pos:"e", neg:"q" }

cMap2.Axes.Throttle.AxisID := "Z"
cMap2.Axes.Throttle.Deadzone := 30 
cMap2.Axes.Roll.Sensitivity := 1
cMap2.Axes.Throttle.AxisKeys := { pos: "w", neg:"s" }

cMap2.HatKeys.X := { pos:"d", neg:"a" }                                
cMap2.HatKeys.Y := { pos:"space", neg:"c" }

cMap1.Buttons.Joy1 := "LButton"
cMap1.Buttons.Joy2 := "o"
cMap1.Buttons.Joy3 := "1"
cMap1.Buttons.Joy4 := "2"
cMap1.Buttons.Joy5 := "3"
cMap1.Buttons.Joy6 := "4"
cMap1.Buttons.Joy7 := "5"
cMap1.Buttons.Joy8 := "6"



class EGSInterface {
	;false is useful for testing
	InGameProcessingOnly := true  
	
	;Set this to 0 to disable throttle function entirely.
	;Throttle works well, but can't work when in menus and 
	;will prevent Alt+Tab to switch apps in windows... (due 
	;to empyrion limitations)                                                   
	GlobalEnableThrottleBinding := 1
	
	WindowName := "Empyrion - Galactic Survival"
	
	;Assign a button that turns the thrust control on and off in-game
	;makes the analog control more friendly - you don't have 
	;to center it to use menus or switch windows
	Hotkey_ToggleThrottle := "1Joy9"                   
	;Button That Switches Between Profiles
	Hotkey_CycleProfile := "-"             

	
	
	
	; internal use
	ThrottleKeyState 	:= false
	RollKeyState 		:= false
	ThottleEnabled 		:= true     
	CurrentProfileIndex	:= 1    
	ProfileList 		:= [cMap1, cMap2]
	
	;Supresses joystick output unless this is the active window  
	CheckSuspended => !WinActive(this.WindowName) && this.InGameProcessingOnly
	
	CurrentProfile => this.ProfileList[this.CurrentProfileIndex}
	
	
	static PressKey(key) {
		Send(Format("`{{1} down`}", key))
	}
	
	static ReleaseKey(key) {
		Send(Format("`{{1} up`}", key))
	}
	
	static TransformAxis(axisData) {
		;transform to 0.0-1.0 range
		normInput := GetKeyState(axisData.JoyID . "Joy" . axisData.AxisID) * 0.01
		;transform to -1-0-+1 range
		dirIn := (normInput - 0.5) * 2
		absDirIn := Abs(dirIn)
		sign := (absDirIn / dirIn)
		;apply deadzone shift		
		deadzone := axisData.deadzone
		dirOut := (absDirIn - deadzone) / (1 - deadzone) * sign
		dirOut *= (this.CurrentProfile.InvertY) ? -1 : 1
		return dirOut * sign < 0 ? 0 : dirOut
	}

	static ApplyRadialDeadzone(vec, deadzone) {
		if(vec.magnitude < deadzone)
			vec := HB_Vector2.zero;
		else
			vec := vec.Normalized.Multiply((vec.magnitude - deadzone) / (1 - deadzone))
			
		return vec
	}
	
	
	HandleInput() {
		Hotkey(this.Hotkey_ToggleThrottle, this.Callback_ToggleThrottle)
		Hotkey{this.Hotkey_CycleProfile,   this.Callback_CycleProfiles)
		
		;setup hat keys 
		this.HatEnabled := false
		hkX := this.CurrentProfile.HatKeysX
		hkY := this.CurrentProfile.HatKeysY
		
		if (hkX.Length && hkY.Length) {
			this.HatEnabled := true
			this.HatKeys := {}
			this.HatKeys.x := [{down: "{" . hkX[1] . " down}", up: "{" . hkX[1] . " up}"}, {down: . "{" . hkX[2] . " down}", up: "{" . hkX[2] . " up}"}]
			this.HatKeys.y := [{down: "{" . hkY[1] . " down}", up: "{" . hkY[1] . " up}"}, {down: . "{" . hkY[2] . " down}", up: "{" . hkY[2] . " up}"}]
		}
		
		physicalController.BindButtons(KEYSLIST)
		
		StartInputHandlers()
	}
	
	
	;hotkey callbacks
	Callback_ToggleThrottle() {
		this.ThottleEnabled := !this.ThrottleEnabled
	}
	
	Callback_CycleProfiles() {
		this.CurrentProfileIndex++
		if (this.CurrentProfileIndex > this.ProfileList.Length)
			this.CurrentProfileIndex := 1
	}

	; start 5ms timers that poll inputs
	StartInputHandlers() {
		SetTimer(this.PollHat, 5)
		SetTimer(this.PollMouseAxes, 5)
		SetTimer(this.PollRollAxis, 5)
		
		if (GlobalEnableThrottleBinding = 1)
			SetTimer(this.PollThrottleAxis, 5)
	}

	PollHat() {
		if (this.CheckSuspended || !this.HatEnabled)
			return
			
		; Process Hat X, Y Axis
		loop (2) {
			new_state := this.HatMap[GetKeyState(HatString), A_Index]
			old_state := HatState[A_Index]
			if (old_state != new_state){
				if (old_state)
					EGSInterface.ReleaseKey(this.HatKeys[A_Index, old_state])
				if (new_state)
					EGSInterface.PressKey(this.HatKeys[A_Index, old_state])
					
				HatState[A_Index] := new_state
			}
		}
	}
	 
	PollRollAxis() {
		this.RollKeyState := ProcessAxisKeys(this.CurrentProfile.Axes.Roll, this.RollKeyState)
	}
	 
	PollThrottleAxis() {
		this.ThrottleKeyState := ProcessAxisKeys(this.CurrentProfile.Axes.Throttle, this.ThrottleKeyState, this.ThottleEnabled)
	}
	 
	 
	PollMouseAxes() {
		if (this.CheckSuspended)
			return
		; Get position of axis assigned for X, centered.
		xInput := EGSInterface.TransformAxis(this.CurrentProfile.Axes.Yaw)
		; Get position of axis assigned for Y, centered and inverted (if required).
		yInput := EGSInterface.TransformAxis(this.CurrentProfile.Axes.Pitch) 
		
		if (abs(xInput) > 0 || abs(yInput) > 0)
		{
			;factor in deadzone and scale back up
			mouseX := xInput * this.CurrentProfile.Axes.Yaw.Sensitivity
			mouseY := yInput * this.CurrentProfile.Axes.Pitch.Sensitivity
			DllCall("mouse_event", "uint", 1, "int", mouseX, "int", mouseY)
		}
	}
	
	
	ProcessAxisKeys(pInputAxis, pKeyState, pEnabled := true) {
		
		deadzone := pInputAxis.Deadzone
		
		minSendRatio := pInputAxis.MinSendDurationRatio
		modTime := pInputAxis.SendModulationTime
		
		posKey := pInputAxis.AxisKeys.pos
		negKey := pInputAxis.AxisKeys.neg
		
		;lost focus, release keys
		if (this.CheckSuspended || !pEnabled) {
			if (pKeyState) {
				EGSInterface.ReleaseKey(posKey)
				EGSInterface.ReleaseKey(negKey)
			}
			return false
		}
		
		axis := EGSInterface.TransformAxis(pInputAxis.Value) 
		if (axis > 0)
			selectedKey := posKey
		else if (axis < 0)
			selectedKey := negKey
		else {
			;axis in deadzone/released. If keystate active 
			;then send 'up' signal for both keys
			if (pKeyState) {
				EGSInterface.ReleaseKey(posKey)
				EGSInterface.ReleaseKey(negKey)
			}
			return false
		}
		
		; Avoid delays between keystrokes.
		SetKeyDelay(-1)  
		
		; just holds key down when at max versus pulsing it
		if (abs(axis) >= 0.9) {
			EGSInterface.PressKey(selectedKey)
			return true
		}

		sendDurationRatio := minSendRatio + axis / (1 - minSendRatio)
	 
		EGSInterface.PressKey(selectedKey)
		Sleep(sendDurationRatio * modTime * pInputAxis.Sensitivity)
		EGSInterface.PressKey(selectedKey)
		Sleep((1 - sendDurationRatio) * modTime * pInputAxis.Sensitivity)
		
		return pKeyState
	}

}