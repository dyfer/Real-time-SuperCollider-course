//OSC
//Arduino
//WebGUI

//------------------------------------------------------------
// --------------------   OpenSoundControl   -----------------
//------------------------------------------------------------

//network-based
//there are many mobile apps to send OSC
// Control (iOS/Android), QuickOSC (Android); TouchOSC (iOS/Android - paid app)
//networking background - see slides 18-21
"http://wiki.dxarts.washington.edu/groups/general/wiki/8722b/attachments/80b10/10.%20Network%20art.pdf".openOS;


//we￼need to be on the same network (usually campus wifi is fine, but not recommended for a performance)
//we need to know our IP addres and port SC is listening on
NetAddr.myIP;
NetAddr.langPort;

//use that to put into TouchOSC
//use any template... I choose LiveControl iPad
//you can also build own templates

//now see what we're getting
OSCFunc.trace(true, true);

OSCFunc.trace(false);

s.quit;//no server status messages for a moment

//in TouchOSC, go to mixer tab, change the first slider
(
~sliderResp = OSCdef(\sliderResp, {arg msg;
	var val;
	// msg.postln;
	val = msg[1];
	val.postln;
}, '/2/fader1')
);
~sliderResp.free;


//---------------
// gui with OSC control
//--------------

//TouchOSC: Mixer tab in LiveControl iPad layout
//reset buttons: /2/push1-8
//sliders: /2/fader1-8
(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;
var allOSCdefs;

allOSCdefs = Array.newClear;

relativeSearchPath = "../02/audio/*.wav"; //configuration

s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
		thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayerWithPan, {|buffer = 0, amp = 1, pan = 0|
		var sig;
		sig = PlayBuf.ar(2, buffer);
		Out.ar(0, Balance2.ar(sig[0], sig[1], pan.lag(0.1), amp.lag(0.1))); //LAGs here
	});

	//create a layout which will space our buttons
	vLayout = VLayout.new;

	//we also need a window
	window = Window.new("simple player", 600@400/*syntactical shorcut to create a Point*/);

	allButtons = allBuffers.collect({|thisBuffer, inc|
		var note, filename, thisButton, thisSlider, thisKnob;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		//before adding more to the layout, let's create the button and ezgui objects first

		thisButton = Button(window)
		.states_([[filename], [filename ++ " playing"]])
		.action_({|buttonObject|
			buttonObject.value.postln;
			if(buttonObject.value.asBoolean, {
				note = synth.note.buffer_(thisBuffer).play;
				// {Synth.basicNew(note.synthdefname, s,note.node).autogui;}.defer(0.1);
			}, {
				note.free;
			});
		});

		thisSlider = EZSlider(window, label: "amp", controlSpec: ControlSpec(0.ampdb, 2.ampdb, \db, units: " dB"), initVal: 0, layout: \horz, unitWidth: 30)
		.action_({|slider|
			if(note.notNil, {
				note.amp_(slider.value.dbamp); //note dbamp here, since we're using decibel scale above (ControlSpec)
			});
		});

		thisKnob = EZKnob(window, controlSpec: \pan, label: "pan", layout: \vert)
		.action_({|knob|
			if(note.notNil, {
				note.pan_(knob.value);
			});
		});


		//OSC here!
		//buttons
		allOSCdefs = allOSCdefs.add(
			OSCdef(\buttonResp ++ inc.asSymbol, {arg msg; //remember about naming your OSCdefs!
				var val;
				val = msg[1];
				{
					if(val == 0, {
						//toggle button value
						if(thisButton.value.asBoolean, {//true when value >0
							thisButton.valueAction = 0;
						}, {
							thisButton.valueAction = 1;
						});
					});
				}.defer; //important: things in the responder can't trigger GUI events directly... need to be deferred (rescheduled using AppClock)
			}, '/2/push' ++ (inc + 1).asSymbol) //this will create OSC responder for paths '/2/push1', '/2/push2', '/2/push3' etc
		);
		//sliders for amps
		allOSCdefs = allOSCdefs.add(
			OSCdef(\sliderResp ++ inc.asSymbol, {arg msg;
				var val;
				val = msg[1];
				{
					thisSlider.valueAction_(thisSlider.controlSpec.map(val)); //no linlin, since we're getting 0-1 values already
				}.defer; //important
			}, '/2/fader' ++ (inc + 1).asSymbol) //this will create responder for faders, see buttons above
		);

		//continue with layout stuff
		vLayout.add( //add to the general layout
			HLayout(
				VLayout(
					thisButton, //button here
					HLayout(
						thisSlider.labelView,
						thisSlider.sliderView,
						thisSlider.numberView.maxWidth_(40), //number box seems the only thing that doesn't scale reasonably by default, so we limit its width here
						thisSlider.unitView //since we've set the unitWidth > 0 above, in slider declaration
					) //use HLayout to set 4 elements of the ezslider
				),
				VLayout(
					thisKnob.labelView,
					thisKnob.knobView,
					thisKnob.numberView.maxWidth_(40) //as above
					//no unitview here since we are not "enabling" it in the declaration
				) //as above
			);
		); //add to layout parenthesis

		thisButton; //we need this to add button to our allButtons variable!
	});

	//add layout to the window
	window.layout_(vLayout);

	//bring the window to front
	window.front;

	//free buffers on close
	window.onClose_({
		"stop all notes - through buttons".postln;
		allButtons.do(_.valueAction_(0));
		"freeing buffers".postln;
		allBuffers.do(_.free);
		allOSCdefs.do(_.free); //free responders
	});

	//see "Char".openHelpFile;
	//also "Dictionary".openHelpFile;

	window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
		var thisIndex, thisButton;
		[char, modifiers, unicode, keycode, key].postln;
		// char.class.postln;
		thisIndex = key - 49;
		"thisIndex: ".post; thisIndex.postln;
		// thisIndex = thisIndex.clip(0, allButtons.size - 1);
		// thisIndex = thisIndex % allButtons.size;
		if((thisIndex >= 0) && (thisIndex < allButtons.size), {
			thisButton = allButtons[thisIndex];
			// "thisButton.value.asBoolean: "a.post; thisButton.value.asBoolean.postln;
			if(thisButton.value.asBoolean, {
				thisButton.valueAction = 0;
				}, {
					thisButton.valueAction = 1;
			});
		});
	});
});
)


//---------------
// simple ambisonics panner
//--------------

//IN PRINCIPLE SHOULD WORK!!!

//we need polar coordinates for that...

a = Point.new(0, 0);
a.theta.raddeg;
a = Point.new(1, 0);
a.theta.raddeg;
a = Point.new(0, 1);
a.theta.raddeg;
//TouchOSC: XY Pad tab in LiveControl iPad layout
//XY pad 1 address: '/5/xy1', provides 2 values

(
var synth, note, resp;
s.waitForBoot({
	synth = CtkSynthDef(\bfNoise, {arg out = 2, amp = 0.5, azimuth = 0;
		Out.ar(out, PanB.ar(PinkNoise.ar(amp), azimuth));
	});
	s.sync; //so the synth is ready before we call it
	note = synth.note.play;

	resp = OSCdef(\panner, {arg msg;
		var vals, point;
		// msg.postln;
		vals = msg[1..2];
		vals = vals - 0.5; //make them from -0.5 to 0.5, i.e. with 0,0 coordinates in the center
		point = Point.new(vals[0], vals[1]);
		// optionally rotate it as needed
		point.rotate(-90.degrad);
		"azimuth: ".post; point.theta.raddeg.postln;
		note.azimuth_(point.theta);
	}, '/5/xy1')
});
CmdPeriod.doOnce({
	resp.free;
});
);


//------------------------------------------------------------
// --------------------   Arduino   --------------------
//------------------------------------------------------------

//communicates over serial ports
//it will send whatever we tell it to...

//Simple approach - Firmata
//needs SCPyduino quark
Quarks.gui; //update quarks first! the install SCPyduino

//load firmata onto Arduino

"SCPyduino".openHelpFile


//we need to open serial port
SerialPort.listDevices //see what's your port name - the one with USB in the name
		//choose appropriate index. You can also cut and paste the path name directly in the port argument
SerialPort.devices[2];
f = SCPyduino.new("/dev/tty.usbmodem1421", 57600); //you need to specify baudrate of 57600! SCPyduino has it set by default to something else...
// e = SCPyduino.new(SerialPort.devices[2], 57600);

f.close; //later


// e = SCPyduino.new(SerialPort.devices[2], 57600); //you can do this, but port order is not guaranteed

//wait ~3s before running subsequent functions...
//firmata looks at arduino as havin 2 8-pin ports (0-7 and 8-13)
//we need to activate port we'd like to use

//important - do it first
f.digitalPorts[0].active_(1); //first 8
f.digitalPorts[1].active_(1); //second 8

//now we can set the pin mode
f.digital[13].mode_(f.digital_output); //works
f.digital[13].write(1); //LED
f.digital[13].write(0);


//PWM output
f.digital[4].mode_(f.digital_pwm); //throws an error since it's not a pwm pin
f.digital[5].mode_(f.digital_pwm); // works
f.digital[5].write(0.5);
f.digital[5].write(0);

//digital input
f.digital[2].mode_(f.digital_input);

f.iterate;//read value from Arduino - this should happen in a loop?
// f.digital[2].value //get it - this doesn't see to work...


//analog input
f.analog[0].active_(1);
f.analog[0].value;

	//post value of analog pin 0
(
a = fork{ //just a Routine
	loop{
		f.iterate;
		f.analog[0].value.postln;
		// f.digital[2].value.postln;
	};
};
)
a.stop;
f.close;
/*
circuit:
5V -> photocell one terminal
photocell another terminal to analog in
the same terminal to a resistor to ground
*/

// ----------
// photocell sound example
// ---------

(
var arduino, synth, note, routine;
arduino = SCPyduino.new("/dev/tty.usbmodem1421", 57600); //you need to specify baudrate of 57600! SCPyduino has it set by default to something else...
s.waitForBoot({
	synth = CtkSynthDef(\simpleSine, {|out = 0, amp = 0.5, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq.lag(0.1), 0, amp), pan))
	});
	s.sync;
	note = synth.note(2).play;

	//analog input
	"waiting for firmata".postln;
	4.wait; //wait works since we are inside a Routine (waitForBoot)
	arduino.analog[0].active_(1);

	//post value of analog pin 0
	routine = Routine.run({ //just a Routine
		loop{
			arduino.iterate;
			// note.freq_(arduino.analog[0].value + 300);
			note.freq_(arduino.analog[0].value.linlin(910, 970, 100, 1200));
		}
	});
});
CmdPeriod.doOnce({
	routine.stop;
	note.free;
	arduino.close; //important!
});
)



// ----------
// alternative/custom communication mode
// ---------


//arduino code
/*

//vars
int hi = 255;
int lo = 0;
int analogPins[] = {
  A0, A1, A2, A3, A4, A5, A0, A1, A2, A3, A4, A5};each sensor read twice, unnecessarily
int analogPinCount;

int digitalPins[] = {
  2, 3, 4, 5};
int digitalPinCount;

int lowBattPin = 5;

//use Serial1 for xBee and Serial for USB
#define serialPort Serial

void setup()
{
  // Open serial
  serialPort.begin(115200);

  analogPinCount = sizeof(analogPins) * 0.5; //0.5 since each member of an array is 2-byte long
  digitalPinCount = sizeof(digitalPins) * 0.5; //0.5 since each member of an array is 2-byte long

  //set inputs
//  for(int thisInput = 0; thisInput < digitalPinCount; thisInput++) {
//    pinMode(digitalPins[thisInput], INPUT_PULLUP);
//  }

//  pinMode(lowBattPin, INPUT); //or INPUT_PULLUP?
}

void loop() // run
{
  sendBeginning();
  sendAnalogIns();
  sendDigitalIns();
  sendEnding();
  //  for debugging
  //  serialPort.println(analogPinCount);
  //  serialPort.println(digitalPinCount);
  //  delay(1000);
//  delay(1);
//  serialPort.println(millis());
}

void sendBeginning()//begin word
{
  serialPort.write(hi);
  serialPort.write(hi);
  serialPort.write(lo);
}

void sendEnding()//end word
{
  serialPort.write(hi);
  serialPort.write(lo);
}

void sendAnalogIns()
{
  for(int thisInput = 0; thisInput < analogPinCount; thisInput++) {
    int thisSensorVal;
    thisSensorVal = analogRead(analogPins[thisInput]);
    serialPort.write(highByte(thisSensorVal));
    serialPort.write(lowByte(thisSensorVal));
  }
}

void sendDigitalIns()
{
  byte buttons = B00000000;//storing button bits
//  for(int thisInput = 0; thisInput < digitalPinCount; thisInput++) {
//    bitWrite(buttons, thisInput, bitRead(digitalRead(digitalPins[thisInput]), 0));
//  };
//  //flip all buttons - maybe need to flip the lowBattPin, to be checked
//  buttons = ~buttons;
//  bitWrite(buttons, 7, digitalRead(lowBattPin));
  serialPort.write(buttons);
}

*/


(
var serial, synth, note, routine;
s.waitForBoot({
	synth = CtkSynthDef(\simpleSineNoLag, {|out = 0, amp = 0.5, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq, 0, amp), pan))
	});
	s.sync;
	note = synth.note.play;


	serial = SerialPort("/dev/tty.usbmodem1411", baudrate: 115200); //open port
	routine = Routine.run({
		var inByte, inArr, inArrClumped, thisCoordArrayVals, cartesianPoints, oldData, isFirstRun, numSensors, sensorRawValues, serialArray, serialArraySize;
		"Starting serial".postln;
		//data format
		//buttons byte - from individual bits lowbatt, 0, 0, 0, rl, ll, rh, lh (sensors stard from LSB)
		//hi hi lo sensor0MSB sensor0LSB sensor1MSB sensor1LSB ... sensor11MSB sensor11LSB buttons hi lo
		numSensors = 12;
		serialArraySize = 6 + (numSensors * 2); // 3 word begin, 12 sensors *2, 1 byte buttons, 2 word end
		serialArray = Array.newClear(serialArraySize);
		inArr = Array.newClear(numSensors);
		inf.do({
			inByte = serial.read; //read data here -------<<<<<<<<<<
			// inByte.postln;
			serialArray = serialArray.shift(-1); //shift existing values left
			serialArray[serialArraySize - 1] = inByte; //put new value to the rightmost slot
			//				serialArray.postln;
			if((serialArray[0]==255 && serialArray[1]==255 && serialArray[2]==0 && serialArray[serialArraySize - 2]==255 && serialArray[serialArraySize - 1]==0), { //recognize the word
				sensorRawValues = serialArray.shift(-3).clipExtend(numSensors * 2); //get raw 2-byte values in th earray
				//get processed data
				numSensors.do({arg i;
					inArr[i] = (sensorRawValues[2*i] << 8) + sensorRawValues[(2*i) + 1];
				});
				// inArr.postln;
				note.freq_(inArr[0] + 300); //get data from analog pin 0
			});
		});
	});


	CmdPeriod.doOnce({
		serial.dump;
		routine.stop;
		note.free;
		serial.close; //important!
	});
});
)


// ----------
// work in progress - a web interface
// ---------

//this requires an extension - WsGUI; not published yet, but I've put it on the website (files -> wsGUI.zip). To install, decompress and copy the whole folder to:
(Platform.userAppSupportDir ++ "/Extensions").openOS;

//see help file
WsWindow.openHelpFile;

//how to use it
a = WsWindow.new("new title", true, 8000); //specify port for using internal static web server; nil when serving www folder using another web server
//now point a web browser to http://localhost:8000 (or http://yourIP:8000)
"http://localhost:8000".openOS;

NetAddr.myIP; //from NetLib; useful for connecting external clients

//background and title
a.background_(Color.blue);
a.background_(Color.white);
a.title_("different title");

//this has some basic widgets: button, text, slider

//text, labels
c = WsStaticText.new(a, Rect(0.5, 0.5, 0.2, 0.2));
c.string_("My text with newline \nhere but also html <br> newline and and and and and and it also wraps long lines");
c.font_(Font.new(\Courier).size_(16));
c.background_(Color.yellow); //change if you don't want the default transparent; setting transparency currently doesn't work
c.background_(Color.white);
c.stringColor_(Color.red);
c.align_(\justify);
c.remove;

//button - add to window immediately
i = WsButton.new(a, Rect(0, 0, 0.2, 0.2)); //WsButton imitates SC style multistate button
(
i.states_([
    ["zero", Color.black, Color.rand],
    ["one", Color.black, Color.rand],
    ["two", Color.black, Color.rand]
]);
)
i.value_(0);
i.value_(1);
i.item;
i.item_("two"); // not implemented
i.states[i.value][0];
i.font_(Font.new(\Georgia).size_(24));
i.action_({|but| "got state: ".post; but.value.postln; "item: ".post; but.item.postln;}); //passed button object now
i.remove;

//slider
k = WsSlider.new(a, Rect(0.1, 0.1, 0.1, 0.4));
k.value_(0);
k.value_(0.7);
k.value;
k.action_({|sl| postf("slider value: %\n", sl.value)})
k.valueAction_(0.3);
k.remove;

//finishing
a.clear //remove all elements, don't close server (can add new elements)
a.free //close ws server
