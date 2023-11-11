#Requires AutoHotkey v2.0
#include "EGSControlMap.ahk"
#include "HB_Vector.ahk"


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

	; These adjust how long the keypress pulse interval is for analog 
	;conversions of Yaw and Thrust. The key will be pressed down a 
	;fraction of this time depending on analog input
	AxisSendModulationTimeZ := 50    
	AxisSendModulationTimeT := 50          
	MinimumSendDurationRatioT := 0.40
	
	
	
	; internal use
	ThrottleKeyState 	:= false
	RollKeyState 		:= false
	ThottleEnabled 		:= true     
	CurrentProfile 		:= cMap1    
	
	
	;Supresses joystick output unless this is the active window  
	CheckSuspended => !WinActive(WindowName) && this.InGameProcessingOnly
	
	
	static PressKey(key) {
		Send(Format("`{{1} down`}", key))
	}
	
	static ReleaseKey(key) {
		Send(Format("`{{1} up`}", key))
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
		
		physicalController.BindButtons()
		
		StartInputHandlers()
	}
	
	
	;hotkey callbacks
	Callback_ToggleThrottle() {
		this.ThottleEnabled := !this.ThrottleEnabled
	}
	
	Callback_CycleProfiles() {
		if (this.CurrentProfile = map1)
			this.CurrentProfile := map2
		else
			this.CurrentProfile := map2
	}

	; start 5ms timers that poll inputs
	StartInputHandlers() {
		SetTimer(this.physicalController.PollHat, 5)
		SetTimer(this.physicalController.PollPitchYawAxes, 5)
		SetTimer(this.physicalController.PollRollAxis, 5)
		
		if (GlobalEnableThrottleBinding = 1)
			SetTimer(this.physicalController.PollThrottleAxis, 5)
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
					Send(HatKeys[A_Index, old_state].up)
					
				if (new_state)
					Send(HatKeys[A_Index, new_state].down)
					
				HatState[A_Index] := new_state
			}
		}
	}
	 
	PollRollAxis() {
		this.RollKeyState := ProcessAxisKeys(this.CurrentProfile.RollInputAxis,
											RollKeys, 
											this.CurrentProfile.RollDeadzone, 
											this.AxisSendModulationTimeZ, 
											this.RollKeyState, 
											this.CurrentProfile.RollSensitivity)
	}
	 
	PollThrottleAxis() {
		this.ThrottleKeyState := ProcessAxisKeys(this.CurrentProfile.ThrottleInputAxis, 
												ThottleKeys, 
												this.CurrentProfile.ThrottleDeadzone, 
												this.AxisSendModulationTimeT, 
												this.ThrottleKeyState,
												1, ;must be 1 for dead-reckoning
												this.MinimumSendDurationRatioT, 
												this.ThottleEnabled)
	}
	 
	 
	PollPitchYawAxes() {
		if (this.CheckSuspended)
			return

		; Get position of axis assigned for X, centered.
		yawInput := GetKeyState(YawInputAxis) - 50  
		yawDZ := this.CurrentProfile.YawDeadZone
		yawSense := this.CurrentProfile.YawSensitivity
		
		; Get position of axis assigned for Y, centered and inverted (if required).
		pitchInput := GetKeyState(PitchInputAxis) - 50 * (this.CurrentProfile.InvertY) ? -1 : 1
		pitchDZ := this.CurrentProfile.PitchDeadzone
		pitchSense := this.CurrentProfile.PitchSensitivity 
		
		if (abs(yawInput) > yawDZ || abs(pitchInput) > pitchDZ)
		{
			;factor in deadzone and scale back up
			mouseX := 0
			if (yawInput > yawDZ)
				mouseX := ((yawInput - yawDZ) * 50 / (50 - yawDZ)) * yawSense
			else if (yawInput < 0 - yawDZ)
				mouseX := ((yawInput + yawDZ) * 50 / (50 - yawDZ)) * yawSense
	  
			mouseY := 0
			if (pitchInput > pitchDZ)
				mouseY := ((pitchInput - pitchDZ) * 50 / (50 - pitchDZ)) * pitchSense
			else if (pitchInput < 0 - pitchDZ)
				mouseY := ((pitchInput + pitchDZ) * 50 / (50 - pitchDZ)) * pitchSense
		  
			DllCall("mouse_event", "uint", 1, "int", mouseX, "int", mouseY)
		}
	}
	
	ProcessAxisKeys(pInputAxis, pDeadzone, pKeyMap, pModulationTime, pKeyState, pSensitivity, pMinSendDurationRatio := 0, pEnabled := true) {
		posKey := pKeyMap[2]
		negKey := pKeyMap[1]
		
		;lost focus, release keys
		if (this.CheckSuspended || !pEnabled) {
			if (pKeyState) {
				EGSInterface.ReleaseKey(posKey)
				EGSInterface.ReleaseKey(negKey)
			}
			return false
		}
		 ; Get raw position of axis.
		axis := this.TransformAxis(GetKeyState(pInputAxis), pDeadzone) 
		
		if (axis > 0)
			selectedKey := pKeyMap[2]
		else if (axis < 0)
			selectedKey := pKeyMap[1]
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
		if (abs(axis) >= 90) {
			EGSInterface.PressKey(selectedKey)
			return true
		}

		val := (abs(axis - 50) - pDeadzone) / (50 - pDeadzone)
		sendDurationRatio := pMinSendDurationRatio + val / (1 - pMinSendDurationRatio)
	 
		EGSInterface.PressKey(selectedKey)
		Sleep(sendDurationRatio * pModulationTime * pSensitivity)
		EGSInterface.PressKey(selectedKey)
		Sleep((1 - sendDurationRatio) * pModulationTime * pSensitivity)
		return pKeyState
	}
	
	TransformAxis(rawIn, deadzone) {
		pctIn := (rawIn / 100)
		dirIn := (pctIn - 0.5) * 2
		
		return Abs(dirIn) < deadzone ? 0 : dirIn
	}
}

ApplyRadialDeadzone(vec, deadzone) {
	if(vec.magnitude < deadzone)
		vec := HB_Vector2.zero;
	else
		vec := vec.Normalized.Multiply((vec.magnitude - deadzone) / (1 - deadzone))
		
	return vec
}

; ; Get raw position of axis.
;rawAxis := GetKeyState(pInputAxis) 
;
;if (rawAxis > 50 + pDeadzone)
;	selectedKey := pKeyMap[2]
;else if (rawAxis < 50 - pDeadzone)
;	selectedKey := pKeyMap[1]
;else {
;	;axis in deadzone/released. If keystate active 
;	;then send 'up' signal for both keys
;	if (pKeyState) {
;		EGSInterface.SendKey(posKey, false)
;		EGSInterface.SendKey(negKey, false)
;	}
;	return false
;}
;
;; Avoid delays between keystrokes.
;SetKeyDelay(-1)  
;
;; just holds key down when at max versus pulsing it
;if (rawAxis > 90 || rawAxis < 10) {
;	EGSInterface.SendKey(selectedKey, true)
;	return true
;}
halfMax := 50
val := (abs(x - halfMax) - pDeadzone) / (halfMax - pDeadzone)
;sendDurationRatio := pMinSendDurationRatio + val / (1 - pMinSendDurationRatio)
;
;EGSInterface.SendKey(selectedKey, true)
;Sleep(sendDurationRatio * pModulationTime * pSensitivity)
;EGSInterface.SendKey(selectedKey, false)
;Sleep((1 - sendDurationRatio) * pModulationTime * pSensitivity)
;return pKeyState