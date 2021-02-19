clearscreen.
print "Duna landing sequence initiated".

// retrograde, heat shield down
PRINT "SETTING SAS".
sas on.
RCS ON.
WAIT 0.0001.
SET SASMODE TO "RETROGRADE".

// determine ship heigth
list parts in partList.
set highestPart to 0.
set lowestPart to 0.
for part in partList{
	set currentPart to vdot(facing:forevector,part:position).
    if currentPart > highestPart
        set highestPart to currentPart.
    else if currentPart < lowestPart
        set lowestPart to currentPart.
}

set height to highestPart - lowestPart.
SET SHIP_RADAR_HEIGHT TO height.
print height.
//ship:geoposition:terrainheight


PRINT "STARTING DESCENT LOGIC".
SET DESIREDVEL TO 200.
SET T TO 0.
LOCK THROTTLE TO T.

set chute_status to false.
set mypid to PIDLoop(0.02, 0.015, .02, 0, 1).

until alt:radar < SHIP_RADAR_HEIGHT + 1{
	// deploy chute when safe
	print "Altitude: " + round(alt:radar,3) + " m" at (0,16).

	// deploy heat shield
	if (SHIP:VELOCITY:SURFACE:MAG < 100 and chute_status){
		for mod in ship:modulesnamed("ModuleDecouple") {
    		if mod:hasevent("jettison heat shield") {
       		 mod:doevent("jettison heat shield").
    		}.
		}.
	}
	// deploy areoshell
	if (alt:radar < 2000){
		for part in ship:parts{
			// stock fairings
			if part:hasmodule("moduleproceduralfairing"){
				local decoupler is part:getmodule("moduleproceduralfairing").
				if decoupler:hasevent("deploy"){
					decoupler:doevent("deploY").
				}
			}
		}
		for mod in ship:modulesnamed("ModuleDecouple"){
			if mod:hasevent("Decouple"){
				mod:doevent("Decouple").
			}
		}
	}
	// cut parachute and start engine under 1000m
	if  (alt:radar<1500 and chute_status ){
		for chute in ship:modulesNamed("ModuleParachute") {
  			chute:doevent("cut parachute").
  			print "parachute cut".
  			set chute_status to false.
 		}.
 		list engines in myengines.
 		for eng in myengines{
 			print "an engine exists with ISP = " + eng:ISP.
 			eng:activate.
 			print "engine activated, throttle controlled descend start".
 		}.
	}.

	// Velocity Control
	if( ALT:RADAR < 25 ) {
		SET DESIREDVEL TO 2.
	}
	else if( ALT:RADAR < 50 ) {
		SET DESIREDVEL TO 5.
		GEAR ON.
	}
	else if( ALT:RADAR < 100 ) {
		SET DESIREDVEL TO 10.
	}
	else if( ALT:RADAR < 1000 ) {
		SET DESIREDVEL TO 15.
	}
	else if( ALT:RADAR < 2000 ) {
		SET DESIREDVEL TO 20.
	}
	else if (alt:radar < 10000){
		chutessafe on.
		chutes on.
		set chute_status to true.
	}

	// This part can be replaced by a PID Controller
	if( SHIP:VELOCITY:SURFACE:MAG > DESIREDVEL ) {
		SET T TO MIN(1, T + 0.05).
	}
	else {
		SET T TO MAX(0, T - 0.05).
	}

	// If we're going up, something isn't quite right -- make sure to kill the throttle.

	//LOCK THROTTLE TO T.
	//set mypid:setpoint to DESIREDVEL.
	//set T to mypid:UPDATE(time:seconds, ship:velocity:surface:mag).
	
	if(SHIP:VERTICALSPEED > 0) {
		SET T TO 0.
	}
 	print "Surface velocity " + round(ship:velocity:surface:mag,1)+ " m/s" at (0,14).
 	print "Desired velocity " + DESIREDVEL + " m/s" at (0,13).
 	//print "PID wants throttle = " + round(T,3) at (0,12).
  	wait 0.001.
}.


PRINT "Touch Down, Shutting Down Engine".
lock throttle to 0.
for eng in myengines{
 	print "an engine exists with ISP = " + eng:ISP.
 	eng:shutdown.
 	print "engine activated, throttle controlled descend start".
}.
wait 5.
brakes on.
rcs off.
unlock steering.
unlock throttle.
 