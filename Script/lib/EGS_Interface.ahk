#Requires AutoHotkey v2.0
#include "EGS_InputConfig.ahk"

class EGS_Interface {
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
	ThottleEnabled 		:= true   
	
	;Button That Switches Between Profiles
	Hotkey_CycleProfile := "-"       
	CurrentProfileIndex	:= 1    
	ProfileList 		:= []     

	; internal state tracking for non-buttons
	ThrottleKeyState 	:= false
	RollKeyState 		:= false
	HatState			:= { X:0 , Y:0 }
	
	__New(inputCfg) {
		this.ProfileList := inputCfg.ControlProfiles
	}
	
	
	;Supresses joystick output unless this is the active window  
	CheckSuspended => !WinActive(this.WindowName) && this.InGameProcessingOnly
	
	CurrentProfile => this.ProfileList[this.CurrentProfileIndex]
	
	
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
	
	
	static ProcessAxisKeys(pInputAxis, pKeyState, pHasControl) {
		
		deadzone := pInputAxis.Deadzone
		
		minSendRatio := pInputAxis.MinSendDurationRatio
		modTime := pInputAxis.SendModulationTime
		
		posKey := pInputAxis.GameKeys.pos
		negKey := pInputAxis.GameKeys.neg
		
		;lost focus or axis disabled, release all keys
		if (!pHasControl) {
			if (pKeyState) {
				EGS_Interface.ReleaseKey(posKey)
				EGS_Interface.ReleaseKey(negKey)
			}
			return false
		}
		
		axis := EGS_Interface.TransformAxis(pInputAxis.Value) 
		if (axis > 0)
			selectedKey := posKey
		else if (axis < 0)
			selectedKey := negKey
		else {
			;axis in deadzone/released. If keystate active 
			;then send 'up' signal for both keys
			if (pKeyState) {
				EGS_Interface.ReleaseKey(posKey)
				EGS_Interface.ReleaseKey(negKey)
			}
			return false
		}
		
		; Avoid delays between keystrokes.
		SetKeyDelay(-1)  
		
		; just holds key down when at max versus pulsing it
		if (abs(axis) >= 0.9) {
			EGS_Interface.PressKey(selectedKey)
			return true
		}

		sendDurationRatio := minSendRatio + axis / (1 - minSendRatio)
	 
		EGS_Interface.PressKey(selectedKey)
		Sleep(sendDurationRatio * modTime * pInputAxis.Sensitivity)
		EGS_Interface.PressKey(selectedKey)
		Sleep((1 - sendDurationRatio) * modTime * pInputAxis.Sensitivity)
		
		return pKeyState
	}

	;static ApplyRadialDeadzone(vec, deadzone) {
	;	if(vec.magnitude < deadzone)
	;		vec := HB_Vector.Zero
	;	else
	;		vec := vec.Normalized.Multiply((vec.magnitude - deadzone) / (1 - deadzone))
	;		
	;	return vec
	;}	
	
	LoadInputProfiles() {
	
	}
	
	
	HandleInput() {
		Hotkey(this.Hotkey_ToggleThrottle, this.Callback_ToggleThrottle)
		Hotkey(this.Hotkey_CycleProfile,   this.Callback_CycleProfiles)
		
		;setup hat keys 		
		this.HatKeysDefined := this.CurrentProfile.HatKeys.X.Length || this.CurrentProfile.HatKeys.Y.Length
		
		this.StartInputHandlers()
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
		SetTimer(this.PollDiscreteHat, 5)
		SetTimer(this.PollMouseAxes, 5)
		SetTimer(this.PollRollAxis, 5)
		
		if (this.GlobalEnableThrottleBinding = 1)
			SetTimer(this.PollThrottleAxis, 5)
	}
	
	StopInputHandlers() {
		SetTimer(this.PollDiscreteHat, 0)
		SetTimer(this.PollMouseAxes, 0)
		SetTimer(this.PollRollAxis, 0)
		SetTimer(this.PollThrottleAxis, 0)
	}

	PollDiscreteHat() {
		if (this.CheckSuspended || !this.HatKeysDefined || physicalController.HasContinuousHat)
			return
		
		new_state := physicalController.HatState	
		old_state := this.HatState
		for (axis,_ in this.HatState) {
			if (old_state.%axis% != new_state.%axis%){
				posKey := this.CurrentProfile.Hat.%axis%.pos
				negKey := this.CurrentProfile.Hat.%axis%.neg
				
				if (old_state.%axis% != 0)
					EGS_Interface.ReleaseKey(old_state.%axis% < 0 ? negKey : posKey)
				if (new_state.%axis% = 0)
					EGS_Interface.PressKey(new_state.%axis% < 0 ? negKey : posKey)
					
				this.HatState.%axis% := new_state.%axis%
			}
		}
	}
	 
	PollRollAxis() {
		this.RollKeyState := EGS_Interface.ProcessAxisKeys(this.CurrentProfile.Axes.Roll, this.RollKeyState, this.CheckSuspended)
	}
	 
	PollThrottleAxis() {
		this.ThrottleKeyState := EGS_Interface.ProcessAxisKeys(this.CurrentProfile.Axes.Throttle, this.ThrottleKeyState, this.CheckSuspended || this.ThottleEnabled)
	}
	 
	 
	PollMouseAxes() {
		if (this.CheckSuspended)
			return
			
		; Get position of axis assigned for X, centered.
		xInput := EGS_Interface.TransformAxis(this.CurrentProfile.Axes.Yaw)
		; Get position of axis assigned for Y, centered and inverted (if required).
		yInput := EGS_Interface.TransformAxis(this.CurrentProfile.Axes.Pitch) 
		
		if (abs(xInput) > 0 || abs(yInput) > 0) {
			;factor in deadzone and scale back up
			mouseX := xInput * this.CurrentProfile.Axes.Yaw.Sensitivity
			mouseY := yInput * this.CurrentProfile.Axes.Pitch.Sensitivity
			DllCall("mouse_event", "uint", 1, "int", mouseX, "int", mouseY)
		}
	}

}