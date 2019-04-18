//DX463
//Fall 2015
//class 03.1

/*
03.1
- Synth vs Ctk approach
- streamline variable declarations
- CtkProtoNotes
- cmdPeriod to free up resources
- slider for synth parameters
- commandPeriod for freeing buffers!
- clocking for the GUI

03.2 (see another file)
- function for creating tasks
- task -> button
- slider for task's/synth's parameters
- multiple tasks, buttons

- lab:
  - extend previous assignment to create:
    - multiple tasks
    - control them on/off with bottons
    - control at least one parameter inside each of them with a slider
- hw
  - use the framework from the lab
  - create more tasks (think modular)
  - control more parameters with sliders
*/



//--------------------------------------------------
// Synth, SynthDef and Ctk
//--------------------------------------------------
s.boot;
//in the help and on the web you'll usually see examples that don't use Ctk... let's see a simple example to see the relation

//Synth and SynthDef classes
(
SynthDef(\SimpleSine, {|freq = 440|
	Out.ar(0, SinOsc.ar(freq, 0, 0.2)) }
).add; //.add is important!
)

// now make a synth from it, using the default value for freq
x = Synth(\SimpleSine);
x.set(\freq, 880);
x.set(\freq, 280);
x.free;
//or with defined value
x = Synth(\SimpleSine, [\freq, 660]);
x.free;

//with Ctk
(
~def = CtkSynthDef(\SimpleSinedifferent, {|freq = 440|
	Out.ar(0, SinOsc.ar(freq, 0, 0.2)) }
); //note no  explicit .add
)
~note = ~def.note.play;
~note.freq_(567);
~note.free;


//--------------------------------------------------
// Streamlining vairable declaration
//--------------------------------------------------

"IdentityDictionary".openHelpFile;
"Dictionary".openHelpFile;
"Symbol".openHelpFile;
//you can use them to aviod having too many variables... there will be more examples on the way
//right now - some abstract example
(
var synths; //variables for other things, not used here
var coolSound, coolerSound, coolestSound, another;

//synths etc...
//...

//notes
coolSound = "some Ctk note";
coolerSound = "some other Ctk note";
coolestSound = "different Ctk note";
another = "yet another Ctk note";

//task/play
// coolSound.play;
// coolerSound.play; etc...
)

//---
//same with a dictionary to group notes into one variable

(
var synths; //variables for other things, not used here
var notes;//no need to declare separate variables

notes = IdentityDictionary.new;

//synths etc...
//...

//notes
notes[\coolSound] = "some Ctk note"; //use any convenient name for dictionary key; shortcut for notes.put(\coolSound, "some Ctk note")
notes[\coolerSound] = "some other Ctk note";
notes[\coolestSound] = "different Ctk note";
notes[\another] = "yet another Ctk note";

//task/play
// notes[\coolSound].play;
// notes[\coolerSound].play; etc...
)


// example adapted from the score-task conversion
//let's say you need to set note's parameters, so we need to assign them to variables. Quickly we can end up with way too many of them
s.reboot;
(
var task, synth, options;
var note0, note1, note2, coolNote; //etc

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
		var osc, osc2, env;
		osc = SinOsc.ar(freq, 0, amp);
		env = Line.kr(1, 0, envDur, doneAction: 0);
		Out.ar(0, osc * env)
	});

//create a notes, DON'T PLAY yet
note0 = synth.note(0, 8).freq_(420).envDur_(8).amp_(0.2);
note1 = synth.note(0, 6).freq_(540).envDur_(6).amp_(0.2);
note2 = synth.note(0, 10).freq_(640).envDur_(10).amp_(0.2);
coolNote = synth.note(0, 6).freq_(1870).envDur_(6).amp_(0.2);

//use task to play and change parameters
task = Task({
	0.2.wait; //wait for 0.2 seconds; same as 0.2.yield
	note0.play; //play the first note
	1.8.wait; //wait
	note0.freq_(1220); //change the frequency while playing
	3.5.wait;
	note1.play; //play the second note
	1.1.wait;
	note1.amp_(0.8); //change amp while playing
	3.1.wait;
	note2.play; //play the first note
	1.8.wait; //wait
	note2.freq_(220); //change the frequency while playing
	4.wait;
	coolNote.play; //play the second note
	1.1.wait;
	coolNote.amp_(0.8); //change amp while playing
	3.1.wait;
});

task.play; //play the task
)

//now version with a dictionary

(
var task, synth, options;
var notes; //just one variable declared for all the notes

notes = IdentityDictionary.new; //create a dictionary

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

//create a notes, DON'T PLAY yet
notes[\note0] = synth.note(0, 8).freq_(420).envDur_(8).amp_(0.2);
notes[\note1] = synth.note(0, 6).freq_(540).envDur_(6).amp_(0.2);
notes[\note2] = synth.note(0, 10).freq_(640).envDur_(10).amp_(0.2);
notes[\coolNote] = synth.note(0, 6).freq_(1870).envDur_(6).amp_(0.2);
//we could freely add notes here, without adding variable declarations

//use task to play and change parameters
task = Task({
	0.2.wait; //wait for 0.2 seconds; same as 0.2.yield
	notes[\note0].play; //play the first note
	1.8.wait; //wait
	notes[\note0].freq_(1220); //change the frequency while playing
	3.5.wait;
	notes[\note1].play; //play the second note
	1.1.wait;
	notes[\note1].amp_(0.8); //change amp while playing
	3.1.wait;
	notes[\note2].play; //play the first note
	1.8.wait; //wait
	notes[\note2].freq_(220); //change the frequency while playing
	4.wait;
	notes[\coolNote].play; //play the second note
	1.1.wait;
	notes[\coolNote].amp_(0.8); //change amp while playing
	3.1.wait;
});

task.play; //play the task
)


//--------------------------------------------------
// CtkProtoNotes
//--------------------------------------------------

//one nice thing about the Synth class is that we don't need to create variables for our synthdefs... but we can have something similar with Ctk. Very handy with multiple SynthDefs!

(
~allSynthDefs = CtkProtoNotes(
	SynthDef(\SimpleSine, {|freq = 440| //NOT CtkSynthDef!
		Out.ar(0, SinOsc.ar(freq, 0, 0.2)) }
	); //note no  explicit .add
);//CtkProtoNotes closing parenthesis
)
~note = ~allSynthDefs[\SimpleSine].note.play; //access like a Dictionary
~note.freq_(567);
~note.free;

//makes more sense with multiple synths
(
~allSynthDefs = CtkProtoNotes(
	SynthDef(\SimpleSine, {|freq = 440| //NOT CtkSynthDef!
		Out.ar(0, SinOsc.ar(freq, 0, 0.2)) }
	), //NOT a semicolon! all SynthDefs are subsequent arguments to CtkProtoNotes
	SynthDef(\SimpleNoise, {|amp = 0.5|
		Out.ar(0, PinkNoise.ar(amp));
	});
);
)
~note = ~allSynthDefs[\SimpleSine].note.play;
~note.freq_(567);
~note.free;

~note2 = ~allSynthDefs[\SimpleNoise].note.play;
~note2.free;


//--------------------------------------------------
// CmdPeriod
//--------------------------------------------------

//if you try things out, or want to have a safer "panic" solution for the performance, you can assign actions to pressing Cmd-.
(
CmdPeriod.doOnce({
	Window.new("I'm a Cmd-. window").front;
});
)

//usually you would like to free buffers there
(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;

relativeSearchPath = "../02/audio/*.wav"; //configuration

s.waitForBoot({
	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
		thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});
	//test play
	{PlayBuf.ar(2, allBuffers.choose)}.play;
	// a = allBuffers;
	CmdPeriod.doOnce({
		"Clearing all buffers!".postln;
		allBuffers.do(_.free);
	});
});
)

//--------------------------------------------------
// using a slider to control frequency
//--------------------------------------------------

(
var task, synth, options;
var window, slider;
var notes; //just one variable declared for all the notes

notes = IdentityDictionary.new; //create a dictionary

//GUI
window = Window.new("slider").front;
window.layout_(
	VLayout(
		slider = Slider.new.orientation_(\horizontal),
		nil//empty space underneath
	)
);

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp); //vs
	// osc = SinOsc.ar(freq.lag(0.05), 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

//create a notes
notes[\note0] = synth.note(0, 18).freq_(420).envDur_(18).amp_(0.2);

//once we have a note assigned to variable, let's use that variable to address it when we move the slider
slider.action_({arg sliderObject;
	var sliderValue;
	sliderValue = sliderObject.value;
	"sliderValue before scaling: ".post; sliderValue.postln;
	//scale it
	sliderValue = (sliderValue * 1000) + 400;
	"sliderValue after scaling: ".post; sliderValue.postln;
	notes[\note0].freq_(sliderValue);
});

//use task to play and change parameters
task = Task({
	0.2.wait; //wait for 0.2 seconds; same as 0.2.yield
	notes[\note0].play; //play the first note
});

task.play; //play the task

//release thinggs
window.onClose_({
	notes.do({arg thisNote;
		thisNote.free;
	});
});
//!!!! what about that discontinuity when changing the frequency? check other option in the synthdef
)

