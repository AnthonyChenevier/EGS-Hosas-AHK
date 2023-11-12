#Requires AutoHotkey v2.0
class EGSControlMap {
	static IDBank: 0
	
	Buttons := []
	Axes := {}
	Hat := {}
	
	
	__New() {
		this.pID := ++IDBank
	}
}

;class MappedAxes {
;	Yaw
;	Pitch
;	Roll
;	Throttle
;	
;}
;class AxisData {
;	AxisID 
;	Sensitivity 
;	Deadzone
;	Inverted
;	SendModulationTime
;	
;}
;class HatData {
;	X
;	Y
;	
;}
