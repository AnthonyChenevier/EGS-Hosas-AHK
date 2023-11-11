;from https://www.autohotkey.com/boards/viewtopic.php?t=89290

Class HB_Vector	{
	
	static Zero => HB_Vector(0,0)
	
	static Distance(vec1, vec2) {
		return Sqrt(((vec1.X - vec2.X) ** 2) + ((vec1.Y - vec2.Y) ** 2))
	}
	
	static Dot(vec1, vec2){
		return vec1.X * vec2.X + vec1.Y * vec2.Y
	}
	
	static Cross(vec1, vec2){
		return vec1.X * vec2.Y - vec1.Y * vec2.X
	}
	
	__New(x:=0,y:=0) {
		this.X := x
		this.Y := y
	}
	
	Add(other) {
		this.X += other.X
		this.Y += other.Y
	}
	
	Subtract(other) {
		this.X -= other.X
		this.Y -= other.Y
	}
	
	Multiply(other){
		if(IsObject(other)) {
			this.X *= other.X 
			this.Y *= other.Y 
		}             
		else if(IsNumber(other)) {
			this.X *= other
			this.Y *= other
		}	
	}
	
	Divide(other){
		if(IsObject(other)){
			this.X /= other.X 
			this.Y /= other.Y 
		}
		else if(IsNumber(other)){
			this.X /= other
			this.Y /= other
		}
	}
	
	MagnitudeSq => this.X * this.X + this.Y * this.Y
	
	Magnitude {
		get { 
			return Sqrt(this.MagnitudeSqr)
		}
		set {
			oldMag := this.Magnitude
			this.X := this.X * value / oldMag
			this.Y := this.Y * value / oldMag
		}
	}
	
	Nomalised {
		get {
			vec := HBVector(this.X, this.Y)
			vec.Normalise()
			return vec
		}
	}
	
	Normalise() {
		oldMag:=this.Magnitude
		this.X/=oldMag
		this.Y/=oldMag
	}
	
}	