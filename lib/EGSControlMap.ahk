#Requires AutoHotkey v2.0
class EGSControlMap {

	YawInputAxis 		:=
	YawSensitivity 		:=
	YawDeadZone 		:=
	PitchInputAxis		:=
	PitchSensitivity 	:=
	PitchDeadZone		:=
	PitchInverted 		:=
	RollInputAxis 		:=
	RollSensitivity 	:=
	RollDeadZone 		:=
	ThrottleInputAxis 	:=
	ThrottleDeadZone 	:=
	
	
	
	
	
	pID :=      
	
	static IDBank: 0
	
	__New() {
		this.pID := ++IDBank
	}
}




; EGSControlMap 1
map1 := new EGSControlMap()
map1.YawInputAxis := "R"
map1.YawSensitivity := 0.5
map1.YawDeadZone := 20
   
map1.PitchInputAxis := "Y"
map1.PitchSensitivity := 0.2
map1.PitchDeadZone := 15
map1.PitchInverted := False
   
map1.RollInputAxis := "X"
map1.RollSensitivity := 0.2
map1.RollDeadZone := 15
map1.RollAxisKeys := { pos:"e", neg:"q" }
   
map1.ThrottleInputAxis := "Z"
map1.ThrottleDeadZone := 30 
map1.ThrottleAxisKeys := { pos: "w", neg:"s" }
   
map1.HatKeys.X := { pos:"d", neg:"a" }                                
map1.HatKeys.Y := { pos:"space", neg:"c" }

; For more info on what to put in for keys, visit: https://www.autohotkey.com/docs/KeyList.htm
map1.Buttons.Joy1 := "LButton"
map1.Buttons.Joy2 := "o"
map1.Buttons.Joy3 := "1"
map1.Buttons.Joy4 := "2"
map1.Buttons.Joy5 := "3"
map1.Buttons.Joy6 := "4"
map1.Buttons.Joy7 := "5"
map1.Buttons.Joy8 := "6"






; EGSControlMap 2  currently set up to switch roll and yaw (leaning stick side to side turns instead of rolls) and does not invert the joystick
map2 := new EGSControlMap()
map2.YawInputAxis := "X"
map2.YawSensitivity := 0.5
map2.YawDeadZone := 20

map2.PitchInputAxis := "Y"
map2.PitchSensitivity := 0.2
map2.PitchDeadZone := 15
map2.PitchInverted := False

map2.RollInputAxis := "R"
map2.RollSensitivity := 0.2
map2.RollDeadZone := 15
map2.RollAxisKeys := { pos:"e", neg:"q" }
   
map2.ThrottleInputAxis := "Z"
map2.ThrottleDeadZone := 30 
map2.ThrottleAxisKeys := { pos: "w", neg:"s" }
   
map2.HatKeys.X := { pos:"d", neg:"a" }                                
map2.HatKeys.Y := { pos:"space", neg:"c" }      
                              
; For more info on what to put in for keys, visit: https://www.autohotkey.com/docs/KeyList.htm
map2.Buttons.Joy1 := "LButton"
map2.Buttons.Joy2 := "o"
map2.Buttons.Joy3 := "1"
map2.Buttons.Joy4 := "2"
map2.Buttons.Joy5 := "3"
map2.Buttons.Joy6 := "4"
map2.Buttons.Joy7 := "5"
map2.Buttons.Joy8 := "6"