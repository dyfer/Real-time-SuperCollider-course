//buses, including ctkcontrol!
//midi responders + pedalboard

//---------------
// Audio Buses tutorial - adapted from Josh Parmenter's notes
//---------------

s.boot;
s.plotTree;
s.scope;

a = s.options.numOutputBusChannels;
b = s.options.numInputBusChannels;
c = s.options.numAudioBusChannels;

c - a - b;

a = CtkAudio.new;
a.bus;

b = CtkAudio.new;
b.bus;

a.free;

c = CtkAudio.new;
c.bus;

c.free; b.free;

//SC's "vanilla" objects:
e = Bus.audio(s, 1);
e.index;
e.free;

/* You can send sound out to ANY audio bus, and read from any bus, even the inputs/outputs */

(
// grab an index in the 'virtual' busses to route to:
a = CtkAudio.new(server: s);

b = CtkSynthDef(\src, {arg outbus;
	Out.ar(outbus, PinkNoise.ar(0.5))
});
)

s.scope;
a.bus;

c = b.note(0.0, 5.0).outbus_(a).play; // pass the CtkAudio object directly; could be a bus number as well
c = b.note(0.0, 5.0).outbus_(0).play; // can use bus number as well... but not recommended for virtual buses
c = b.note(0.0, 5.0).outbus_(2).play;

(
// now - any note can READ and use the routed sound in its own synthesis process:
d = CtkSynthDef(\filter, {arg inbus, pan, filterFreq, filterRq, amp = 1, gate = 1;
	var src, filter, env;
	src = In.ar(inbus, 1);
	env = EnvGen.kr(
		Env([0, 1, 0], [0.1, 0.1], \sin, 1),
		gate);
	filter = Resonz.ar(src, filterFreq, filterRq);
	Out.ar(0, Pan2.ar(filter * env * amp, pan))
});
)


(
// start the source
c = b.note.outbus_(a).play; // just give the argument the CtkAudio object...

// start the filter ...
e = d.note.inbus_(a) // feed in a
	.pan_(0.5.rand2)
	.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [5])))
	.filterRq_(0.01)
	.amp_(12.dbamp)
	.play;
)

s.queryAllNodes;

c.free; e.free;

// ????????
// Order of Execution


(
// start the source
c = b.note.outbus_(a).play; // just give the argument the CtkAudio object...
// start the filter ...
//possible addAction: \before, \after, \head, \tail
e = d.note(addAction: \after, target: c).inbus_(a) // feed in a
	.pan_(0.5.rand2)
	.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [5])))
	.filterRq_(0.01)
	.amp_(12.dbamp)
	.play;
)

s.queryAllNodes;

c.free; e.free;
//more notes
(
// start the source
c = b.note.outbus_(a).play; // just give the argument the CtkAudio object...
// start the filter ...
// d.new(0.0, 5, addAction: \tail, target: 1).inbus_(a) // feed in a
e = d.note(addAction: \tail).inbus_(a) // feed in a
	.pan_(0.5.rand2)
	.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [5])))
	.filterRq_(0.01)
	.amp_(12.dbamp)
	.play;
// d.new(0.0, 5, addAction: \tail, target: 1).inbus_(a) // feed in a
f = d.note(addAction: \tail).inbus_(a) // feed in a
	.pan_(0.5.rand2)
	.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [5])))
	.filterRq_(0.01)
	.amp_(12.dbamp)
	.play;
// d.new(0.0, 5, addAction: \tail, target: 1).inbus_(a) // feed in a
g = d.note(addAction: \tail).inbus_(a) // feed in a
	.pan_(0.5.rand2)
	.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [5])))
	.filterRq_(0.01)
	.amp_(12.dbamp)
	.play;
)

s.queryAllNodes;

c.free; e.free; f.free; g.free;



// clean up
a.free;



//---------------
// Task examples that use multiple notes to read from one source
//---------------


(
var routebus, src, filter, score;

routebus = CtkAudio.new(server: s);

src = CtkSynthDef(\src, {arg outbus;
	Out.ar(outbus, PinkNoise.ar(0.5))
});

filter = CtkSynthDef(\filter, {arg inbus, pan, noteDur, filterFreq, filterRq, amp = 1;
	var src, filter, env;
	src = In.ar(inbus);
	env = EnvGen.kr(
		Env([0, 1, 1, 0], [0.1, 0.8, 0.1], \sin),
		timeScale: noteDur);
	filter = Resonz.ar(src, filterFreq, filterRq);
	Out.ar(0, Pan2.ar(filter * env * amp, pan))
});



Task({
	var srcNote;
	srcNote = src.note.outbus_(routebus).play; // defaults to the \head of group 1

	20.do({
		var thisDur;
		thisDur = 12.0.rrand(10.0);
		filter.note(0, thisDur , addAction: \tail, target: 1).inbus_(routebus)
		.pan_(0.5.rand2)
		.noteDur_(thisDur)
		.filterFreq_(CtkControl.env(Env([2000.rrand(1000), 1000.rrand(500)], [thisDur], \exp)))
		.filterRq_(0.001)
		.amp_(12.dbamp)
		.play;
		0.1.rrand(8.0).wait;
	});

	5.wait; //free afterwards... ideally should be triggered manually, e.g. when triggering buses
	srcNote.free;
	routebus.free;

}).play;

)

//---------------
// Task examples that uses routing to add reverb to everything
//---------------

(
var task, synths, options, times, freqs, amps, routebus;

s.plotTree;

routebus = CtkAudio.new(2, server: s); //specify 2 channels!

synths = CtkProtoNotes(
	SynthDef(\oscili,  {arg freq, envDur, pan = 0, amp = 1, out = 0;
		var osc, osc2, env;
		osc = SinOsc.ar(freq, 0);
		env = Line.kr(1, 0, envDur, doneAction: 0);
		Out.ar(out, Pan2.ar(osc * env, pan, amp));
	}),
	SynthDef(\reverb, {arg in = 0, out = 0, roomsize = 30, revtime = 2, damping = 0.6, inputbw = 0.8, spread = 15, drylevel = 0.5, earlylevel = 0.4, taillevel = 0.2;
		var inSnd, revSnd;
		inSnd = In.ar(in, 2); //2 channel input
		revSnd = GVerb.ar(
        inSnd.sum, //GVerb accepts mono input only!
        roomsize,
        revtime,
        damping,
        inputbw,
        spread,
        0, //drylevel - 0 here
        earlylevel,
        taillevel,
        roomsize);
		Out.ar(out, (inSnd * drylevel) + revSnd);
	})
);

times = [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ]; //relative times
freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

//no need to have incremented "now" variable

task = Task({
	var revNote;
	// start the reverb
	// revNote = synths[\reverb].note(addAction: \tail).in_(routebus).out_(0).roomsize_(30).revtime_(4.2).damping_(0.6).inputbw_(0.8).spread_(15).drylevel_(-16.dbamp).earlylevel_(-12.dbamp).taillevel_(-18.dbamp).play;
	revNote = synths[\reverb].note(addAction: \tail).in_(routebus).out_(0).roomsize_(30).revtime_(4.2).damping_(0.6).inputbw_(0.8).spread_(15).drylevel_(-6.dbamp).earlylevel_(0).taillevel_(0).play; //no reverb version
	times.size.do({arg inc;
		"current time diff: ".post; times[inc].postln;
		times[inc].wait; //wait for a specified time
		synths[\oscili].note(0, 2.0, addAction: \head /*but this is the default anyway*/).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]).out_(routebus).play; //
		// synths[\oscili].note(0, 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]).out_(routebus).play;
	});
	8.wait;
	//freeeeeeee
	revNote.free;
	routebus.free;
});
task.play;//play the dask
)


//---------------
// Buses - control
//---------------


//seaparate from audio set of numbered buses, used to transmit control signals

a = CtkControl.play; //why play? so we can use it in realtime right away
a.bus;

b = CtkControl.play;
b.bus;

a.free;

c = CtkControl.play;
c.bus;

c.free; b.free;

//SC's "vanilla" objects:
e = Bus.control(s, 1);
e.index;
e.free;


//simple example
a = CtkControl.play;
a.bus;
s.scope(1, a.bus, rate: \control)
a.set(0.1)
a.set(80)

(
var synths;
s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus = 0, freq, amp, dur, gate = 1;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env([0, 1, 0], [0.01, 2], \sin, 1), gate, doneAction: 2),
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);
	s.sync;
	~note = synths[\singrain].note.freq_(a).amp_(-12.dbamp).dur_(50).outbus_(0).play;
});
)

a.set(280)
a.set(1800)
a.set(120)
~note.release;
a.get({|index, val| val.postln}); //get data from CtkControl - asynchronous


s.plotTree

(
var synths;
synths = CtkProtoNotes(
	SynthDef(\freqCtrl, {arg outbus, startingValue = 100, endingValue = 10, time = 2, curve = 0;
		Out.kr(outbus,
			EnvGen.kr(Env([startingValue, endingValue], [time], curve), doneAction: 2)
		)
	})
);

a.get({|index, val|
	synths[\freqCtrl].note.outbus_(a).startingValue_(val).endingValue_(400).time_(1).curve_(4).play;
});
)

(
var synths;
synths = CtkProtoNotes(
	SynthDef(\lfSawCtrl, {arg outbus, freq = 0.1, mul = 100, add = 400, ctrlInTime = 1;
		var xFadeEnv, inSig;
		xFadeEnv = EnvGen.kr(Env([0, 1], [ctrlInTime]));
		inSig = In.kr(outbus, 1);
		Out.kr(outbus,
			inSig * (1 - xFadeEnv) + (SinOsc.kr(freq, 0, mul, add) * xFadeEnv)
			// SinOsc.kr(freq, 0, mul, add) //compare
		)
	})
);
~ctrlNote = synths[\lfSawCtrl].note(0.1).outbus_(a).freq_(0.5).mul_(200).add_(1600).play;

)



~ctrlNote.free;
~note.free;
a.free;



//------------------------------------------------------------
// --------------------   MIDI   --------------------
//------------------------------------------------------------

//Musical Instrument Digital Interface
//originally mostly for keyboards
//it's a serial communication protocol

//we'll focus on receiving... but it's possible to send messages both ways obviously
"MIDI".openHelpFile;

//need to run this first
//once after recompiling the library
//but doesn't hurt to re-run!
MIDIClient.init;
MIDIIn.connectAll; //to use all midi ports

MIDIClient.sources //list
MIDIClient.destinations //list

//you can also use specific port only:
//MIDIIn.connect(MIDIIn.findPort("nanoKONTROL2", "SLIDER/KNOB")); //this needs to be exactly as MIDIEndPoint reports

//various controllers offer different midi modes
//korg nanoKontrol2 offers a "cc mode" and various DAW modes
//see the manual
"http://i.korg.com/uploads/Support/nanoKONTROL2_OM_EFGSC1_634479704051940000.pdf".openOS;


//let's have a quick look at the messages received
MIDIFunc.trace(true);

//turn off
MIDIFunc.trace(false);

//there are various types of midi messages
//we'll be dealing with "continuous controllers" (abbreviated cc)
//other types of messages: noteOn, noteOff, program, bend (pitch bend wheel)
//most values are within range 0-127
//within each type, messages have channel (0-15), controler/key number (0-127), and the actual value (0-127)
//SC also identifies sources - which port the message came from

//korg uses only cc messages

//look again at the trace messages

//remember OSCdef? there MIDIdef as well
"MIDIdef".openHelpFile;

//*cc (key, func, ccNum, chan, srcID, argTemplate, dispatcher)
//function
//When evaluated for noteOn, noteOff, control, and polytouch messages it will be passed the arguments val, num, chan, and src. For touch, programme change and bend messages it will be passed only val, chan, and src.
(
~sliderResp = MIDIdef.cc(\testResponder, {arg val, num, chan, src;
	"val, num, chan src: ".post; [val, num, chan, src].postln;
}, nil, nil, nil/*or put MIDIEndPoint instance here, as with MIDIIn*/)
)
~sliderResp.free;

//to be ready to plug it into something, let's make a note about control numbers:
//first slider - cc #0
//first knob - cc #16
//first "S" button - cc #32
//first "M" button - cc #48
//first "R" button - cc #64
//other cc numers:
//track <> - 58-59, cycle - 46, rew - 43, ff - 44, stop - 42, play - 41, rec - 45, marker set - 6-, marker <> - 61-62
//for buttons - value is 127 when pressed and 0 when released
//we'll be triggering things on release - in my experience better for performance



//---------------
// slider -> CtkControl
//--------------

(
var synths, ctrlBus;
s.waitForBoot({
	ctrlBus = CtkControl.play;
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus = 0, freq, amp, dur, gate = 1, lagTime = 0.5;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq.lag(lagTime), 0, amp) * EnvGen.kr(Env([0, 1, 0], [0.01, 2], \sin, 1), gate, doneAction: 2),
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);
	s.sync;
	~note = synths[\singrain].note.freq_(ctrlBus).amp_(-12.dbamp).dur_(50).outbus_(0).play;
});

~sliderResp = MIDIdef.cc(\testResponder, {arg val, num, chan, src;
	var scaledValue;
	"val, num, chan src: ".post; [val, num, chan, src].postln;
	// scaledValue = val.linexp(0, 127, 50, 2000);
	scaledValue = val.linexp(0.001, 127, 0.001, 2.0);
	ctrlBus.set(scaledValue);
}, 0, nil, nil/*or put MIDIEndPoint instance here, as with MIDIIn*/)
)

~note.release; ~sliderResp.free;

s.scope


//---------------
// more ezGUIs - now with MIDI!
//--------------

(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;
var allMIDIdefs;

allMIDIdefs = Array.newClear;

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
		Out.ar(0, Balance2.ar(sig[0], sig[1], pan, amp));
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


		//MIDI here!
		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\sResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
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
			}, 32 + inc) //this will create responder for cc number (0+inc), so for the "S" buttons (providing we don't have more than 8 files!)
		);

		//but needs to be like this for the time being
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
		allMIDIdefs.do(_.free); //free responders
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
// GUI, MIDI with amps and pans
//--------------

(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;
var allMIDIdefs;

allMIDIdefs = Array.newClear;

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
		Out.ar(0, Balance2.ar(sig[0], sig[1], pan, amp));
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


		//MIDI here!
		//buttons
		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\sResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
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
			}, 32 + inc) //this will create responder for cc number (32+inc), so for the "S" buttons (providing we don't have more than 8 files!)
		);
		//sliders for amps
		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\sliderResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
				{
					thisSlider.valueAction_(thisSlider.controlSpec.map(val.linlin(0, 127, 0, 1))); //use slider's controlspec to scale properly; note that controlspec required input between 0 and 1, thus .linlin(0, 127, 0, 1)
				}.defer; //important
			}, 0 + inc) //this will create responder for cc number (0+inc), so for the sliders
		);

		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\panResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
				{
					thisKnob.valueAction_(thisKnob.controlSpec.map(val.linlin(0, 127, 0, 1)));
					}.defer; //important
				}, 16 + inc) //this will create responder for cc number (0+inc), so for the knobs
			);

			//but needs to be like this for the time being
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
			allMIDIdefs.do(_.free); //free responders
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


//note limited resolution of standard midi messages (just 128 steps)
//there are interfaces that send higher resolution data, but these are more rare and rather hi-end

//to solve possible artifacts in sound, use .lag with a short time on the input

//---------------
// GUI, MIDI with amps, pans and LAG (see synths)
//--------------

(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;
var allMIDIdefs;

allMIDIdefs = Array.newClear;

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


		//MIDI here!
		//buttons
		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\sResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
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
			}, 32 + inc) //this will create responder for cc number (32+inc), so for the "S" buttons (providing we don't have more than 8 files!)
		);
		//sliders for amps
		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\sliderResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
				{
					thisSlider.valueAction_(thisSlider.controlSpec.map(val.linlin(0, 127, 0, 1))); //use slider's controlspec to scale properly; note that controlspec required input between 0 and 1, thus .linlin(0, 127, 0, 1)
				}.defer; //important
			}, 0 + inc) //this will create responder for cc number (0+inc), so for the sliders
		);

		allMIDIdefs = allMIDIdefs.add(
			MIDIdef.cc(\panResp ++ inc.asSymbol, {arg val, num, chan, src; //remember about naming your MIDIdefs!
				"val, num, chan src: ".post; [val, num, chan, src].postln;
				{
					thisKnob.valueAction_(thisKnob.controlSpec.map(val.linlin(0, 127, 0, 1)));
				}.defer; //important
			}, 16 + inc) //this will create responder for cc number (0+inc), so for the knobs
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
		allMIDIdefs.do(_.free); //free responders
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


//------------
//LAG or no lag? let's see the differente
//------------

(
var synths, notes, responders;

synths = CtkProtoNotes(
	SynthDef(\simpleSineNoLag, {|out = 0, amp = 0.5, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq, 0, amp), pan))
	}),
	SynthDef(\simpleSineLag, {|out = 0, amp = 0.5, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq, 0, amp.lag(0.1)), pan.lag(0.1)))
	})
);


notes = [
	synths[\simpleSineNoLag].note.freq_(rrand(567, 842)).pan_(-0.5).play, //comma here! it's an array!
	synths[\simpleSineLag].note.freq_(rrand(567, 842)).pan_(0.5).play
];

responders = [
	MIDIdef.cc(\slider0, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var amp, spec;
		spec = ControlSpec(0.ampdb, 1.ampdb, \db);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		amp = spec.map(val.linlin(0, 127, 0, 1));
		"amp (dB): ".post; amp.postln;
		notes[0].amp_(amp.dbamp); //!!!dbamp here
	}, 0),
	MIDIdef.cc(\slider1, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var amp, spec;
		spec = ControlSpec(0.ampdb, 1.ampdb, \db);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		amp = spec.map(val.linlin(0, 127, 0, 1));
		"amp (dB): ".post; amp.postln;
		notes[1].amp_(amp.dbamp); //!!!dbamp here
	}, 1),
];

CmdPeriod.doOnce({
	responders.do(_.free);
	notes.do(_.free);
});
)

(
var synths, notes, responders;

synths = CtkProtoNotes(
	SynthDef(\simpleSineNoLag, {|out = 0, amp = 0.25, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq, 0, amp), pan))
	}),
	SynthDef(\simpleSineLag, {|out = 0, amp = 0.25, freq = 573, pan = 0|
		Out.ar(out, Pan2.ar(SinOsc.ar(freq.lag(0.5), 0, amp.lag(0.5)), pan.lag(0.5)))
	})
);


notes = [
	synths[\simpleSineNoLag].note.freq_(rrand(567, 842)).pan_(-0.5).amp_(-40.dbamp).play, //comma here! it's an array!
	synths[\simpleSineLag].note.freq_(rrand(567, 842)).pan_(0.5).amp_(-40.dbamp).play
];

responders = [
	MIDIdef.cc(\freq0, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var freq, spec;
		spec = ControlSpec(80, 2000);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		freq = spec.map(val.linlin(0, 127, 0, 1));
		"freq: ".post; freq.postln;
		notes[0].freq_(freq);
	}, 2),
	MIDIdef.cc(\freq1, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var freq, spec;
		spec = ControlSpec(80, 2000);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		freq = spec.map(val.linlin(0, 127, 0, 1));
		"freq: ".post; freq.postln;
		notes[1].freq_(freq);
	}, 3),
	MIDIdef.cc(\slider0, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var amp, spec;
		spec = ControlSpec(0.ampdb, 1.ampdb, \db);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		amp = spec.map(val.linlin(0, 127, 0, 1));
		"amp (dB): ".post; amp.postln;
		notes[0].amp_(amp.dbamp); //!!!dbamp here
	}, 0),
	MIDIdef.cc(\slider1, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		var amp, spec;
		spec = ControlSpec(0.ampdb, 1.ampdb, \db);
		"val, num, chan src: ".post; [val, num, chan, src].postln;
		amp = spec.map(val.linlin(0, 127, 0, 1));
		"amp (dB): ".post; amp.postln;
		notes[1].amp_(amp.dbamp); //!!!dbamp here
	}, 1),
];

CmdPeriod.doOnce({
	responders.do(_.free);
	notes.do(_.free);
});
)


//another example - ProcModR & MIDI controller!!

//------------------------------------------
// ProcEvents - more procs at the same time
//------------------------------------------

(
var synths, pmFuncs, pEvents;
var firstOutputChannel, recordProcsToDisk, recordPath;
var allMIDIdefs;
firstOutputChannel = 0;
recordProcsToDisk = false; //so we can switch it on/off easily
recordPath = "".resolveRelative; //just the same path as our SC file
recordPath.postln;
pmFuncs = IdentityDictionary.new;

~maxFreqGlobal = 1800;

synths = CtkProtoNotes(
	SynthDef(\singrain, {arg outbus, freq, amp, dur;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.sine(dur, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	}),
	SynthDef(\percsin, {arg outbus, freq, amp, dur, att = 0.01;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.perc(att, dur - att, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	}),
	SynthDef(\tapdelay, {arg outbus, inbus, buffer;
		Out.ar(outbus,
			MultiTap.ar(
				`[[0.1, 0.32, 0.43, 0.54], [0.2, 0.42, 0.53, 0.64]],
				`[1, 0.8, 0.67, 0.6],
				In.ar(inbus, 2),
				bufnum: buffer
			)
		)
	})
);

pmFuncs[\slow] = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
	var proc, fxBus, delayBuffer;
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s
	);
	// recordProcsToDisk.postln;
	// recordPath.postln;
	if(recordProcsToDisk, {
		proc.recordPM(recordPath); //init recording here
	});
	proc.function_({arg group, routebus, server;
		Task({
			fxBus = CtkAudio(2, server: s);
			delayBuffer = CtkBuffer(size: s.sampleRate * 2, numChannels: 2).load; //loading buffer here might not be the best since it takes time;
			server.sync;
			synths[\tapdelay].note(server: server, target: group, addAction: \tail).outbus_(routebus).inbus_(fxBus).buffer_(delayBuffer).play; //start delay
			inf.do({
				synths[\percsin].note(server: server, target: group)
				.freq_(rrand(minFreq, if(maxFreq.isKindOf(Function), {
					maxFreq.value
					}, {
						maxFreq
				}))) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(fxBus)
				// .outbus_(routebus)
				.play; //this is one line of code, BTW
				1.5.wait;
			})
		});
	});
	proc.onReleaseFunc_({arg group, routebus, server;
		"I'm triggered when the release STARTS".postln;
		synths[\percsin].note(server: server, target: group)
		.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
		.amp_(-9.dbamp)
		.dur_(5)
		.outbus_(routebus)
		.play;
	});
	proc.releaseFunc_({
		id.post; " is done. You can free resources needed for this procmod (like Buses) here.".postln;
		[delayBuffer, fxBus].do(_.free); // <-- free the bus and the buffer here!
		"This will not get triggered if you never play and release the proc... plan accordingly!".postln;
	});

	proc; //make sure the function returns this proc
};



pmFuncs[\fast] = {arg id = \fastPerf, amp = 0.dbamp, att = 1, rel = 5;
	var proc, fxBus, delayBuffer;
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s
	);
	if(recordProcsToDisk, {
		proc.recordPM(recordPath); //init recording here
	});
	proc.function_({arg group, routebus, server;
		Task({
			100.do({|i|
				synths[\percsin].note(server: server, target: group).freq_(rrand(40, 6450)).amp_(-18.dbamp).play;
				(0.01 + 0.05.rand).wait;
			});
		});
	});
	proc; //make sure the function returns this proc
};
//events - an array of events (ProcMods or a function) to play / release  in the following format: [ProcMod, ProcMod.id to release]
pEvents = ProcEvents.new(
	[
		[//event 0
			~p1 = pmFuncs[\slow].(\nameOne, -12.dbamp, 880, {~maxFreqGlobal}, rel: 1),
			nil //nothing to release
		], [//event 1
			[
				pmFuncs[\slow].(\nameTwo, -3.dbamp, 100, 302, rel: 10),
				pmFuncs[\fast].(\nameFast, -3.dbamp),
			],
			nil,
		], [//event 2
			nil, //nothing to start
			[\nameOne, \nameFast] //release these ones
		], [//event 3
			nil,
			\nameTwo
		]
	], //all events array
	0.dbamp, //global amp
	nil, //initial procMod, starts with the first event
	ProcMod.new.function_({"Freeing MIDI functions".postln; allMIDIdefs.do(_.free)}),
	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	server: s
);

// pEvents.perfGUI; //gui for advancing
pEvents.pracGUI; //for some reason recording works only with practice gui

//MIDI stuff
allMIDIdefs = [
	MIDIdef.cc(\play, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		{
			if(val == 0, {
				pEvents.next; //this might be more suitable for fast forward button maybe?
				// pEvents.play(pEvents.index); //also try
			});
		}.defer;
	}, 41),
	MIDIdef.cc(\stop, {arg val, num, chan, src;
		{
			if(val == 0, {
				pEvents.releaseAll;
			});
		}.defer;
	}, 42),
	MIDIdef.cc(\next, {arg val, num, chan, src; //remember about naming your MIDIdefs!
		{
			if(val == 0, {
				pEvents.index = pEvents.index + 1;
			});
		}.defer;
	}, 62),
	MIDIdef.cc(\previous, {arg val, num, chan, src;
		{
			if(val == 0, {
				pEvents.index = pEvents.index - 1;
			});
		}.defer;
	}, 61),
	MIDIdef.cc(\reset, {arg val, num, chan, src;
		{
			if(val == 0, {
				pEvents.reset;
			});
		}.defer;
	}, 43),
];

//optionally automatically create amp controllers using pEvents.eventDict
pEvents.eventDict.keysValuesDo({|key, value|
	[key, value].postln;
});
~pE = pEvents; //for testing etc
)
~pE
~pE.dump //useful

~pE.eventDict[\nameOne].amp_(0.75)
~pE.eventDict[\nameOne].amp

