//DX463
//Fall 2015
//class 05



//----------------------------------------------------------------
//Reminder: coding practices
//----------------------------------------------------------------

//keep it organized
//variables
//general settings (output number etc)
//functions
//synths
//then tasks and music making
//GUI

//also group variable declarations
//use dictionary for musical gestures, notes and similar things
//use CtkProtoNotes

//use relative paths for soundfiles, I suggest keeping them in the same (sub-)folder as your SC code

//avoid global variables! (except for prototyping)

//use comments, so you can remember what's happening when revisiting the code

//put () around your whole code - your piece should run from a single block!

//if you need to copy/paste, think if you can iterate instead (.do/.collect etc)

//free necessary things and reload on each run - use window.onClose_({function}) or CmdPeriod.doOnce({function}) (note slightly different syntax - lack of underscore for CmdPeriod
//what needs to be freed? buffers, responders (more on that later), groups, individual notes



//--------------------------------------------------
// General settings - making your projects configurable
//--------------------------------------------------

//use a variable for first audio output used
//same for input (offset with s.options.numOutputBusChannels)
//include a masterVolume variable which you will use to multiply everything (either one synth where all the audio is routed or each separate synth if no global router/decoder synth is used)
var masterVol, outputNumber;
masterVol = -3.dbamp; //dbamp here
outputNumber = 0; //0 - first audio output
...
mySynth = Ctk...(\name {|outbus = 0|
	Out.ar(outbus, myAwesomeSignal * masterVol) //multiply your signal by
});
...
mySynth.note.outbus_(ouputNumber).play; //specify output for the synth when creating the note, NOT inside the synth definition


//--------------------------------------------------
// Envelopes and doneAction
//--------------------------------------------------

//envelope definition

"Env".openHelpFile;
e = Env.new([0, 1, 0.9, 0], [0.1, 0.5, 1]);
e.plot; //we can plot this
Env.new([0.001, 1, 0.9, 0.001], [0.1, 0.5, 1],\exp).plot; //with envelope curves
Env.new([0, 1, 0.9, 0], [0.1, 0.5, 1], releaseNode: 2).plot; //plots the same, but will be useful with EnvGen
//also useful predefined envelopes:
Env.perc.plot; //fixed length
Env.adsr.plot; //has a release node defined


//vs envelope ugen
"EnvGen".openHelpFile;
//you need to pass an Env (the definition)
EnvGen.kr(e);

//doneActions
"UGen done-actions".openHelpFile; //the one we're interested in is number 2

//no doneAction
e = Env.new([0, 1, 0.9, 0], [0.1, 0.5, 1]);
e.plot;
x = {PinkNoise.ar(EnvGen.kr(e) * -12.dbamp)}.play;//note number of synths
x.free

//with doneAction
e = Env.new([0, 1, 0.9, 0], [0.1, 0.5, 1]);
x = {PinkNoise.ar(EnvGen.kr(e, doneAction: 2) * -12.dbamp)}.play;//note number of synths
x.free //no need for this, synth frees itself





//in synthdef
(
~synthDefs = CtkProtoNotes(
	SynthDef(\SimpleNoiseEnv, {|out = 0, minFreq = 40, maxFreq = 10000, amp = 0.5, pan = 0|
		var envDef, envGen, snd;
		envDef = Env.new([0, 1, 0.9, 0], [0.1, 0.5, 1]);
		envGen = EnvGen.kr(envDef, doneAction: 2);
		snd = PinkNoise.ar;
		Out.ar(out, Pan2.ar(snd, pan, amp) * envGen) //multiply your output by the output of envgen
	}),
	SynthDef(\SimpleNoiseEnvSustaining, {|out = 0, minFreq = 40, maxFreq = 10000, amp = 0.5, pan = 0, gate = 1, relNode = 1| //note we have gate here now
		var envDef, envGen, snd;
		envDef = Env.new([0, 1, 0], [0.1, 1], releaseNode: relNode); //releaseNode - last segment
		envGen = EnvGen.kr(envDef, gate, doneAction: 2); //specify gate here
		snd = PinkNoise.ar;
		Out.ar(out, Pan2.ar(snd, pan, amp) * envGen) //multiply your output by the output of envgen
	}),
	SynthDef(\SimpleNoiseEnvSustainingShort, {|out = 0, minFreq = 40, maxFreq = 10000, amp = 0.5, pan = 0, gate = 1, att = 0.01, rel = 2, decTime = 0, susLevel = 1| //note we have gate here now
		var env, snd;
		env = EnvGen.kr(Env.adsr(att, decTime, susLevel, rel), gate, doneAction: 2); //Env.adsr
		snd = PinkNoise.ar;
		Out.ar(out, Pan2.ar(snd, pan, amp) * env) //multiply your output by the output of envgen
	})
);
)

a = ~synthDefs[\SimpleNoiseEnv].note.play; //stops itself

b = ~synthDefs[\SimpleNoiseEnvSustaining].note.play; //keeps going
b.release; //frees itself after releasing
b.free; //vs free


c = ~synthDefs[\SimpleNoiseEnvSustainingShort].note.play; //keeps going
c.release; //frees itself after releasing

c = ~synthDefs[\SimpleNoiseEnvSustainingShort].note.att_(1.8).play; //keeps going
c.release


//--------------------------------------------------
// Using Mouse input for control
//--------------------------------------------------

x = { SinOsc.ar(MouseX.kr(40, 10000, 1), 0, 0.1) }.play;
x.free;

//using SynthDef
(
~synthDefs = CtkProtoNotes(
	SynthDef(\SimpleSineMouse, {|out = 0, minFreq = 40, maxFreq = 10000, amp = 0.5, pan = 0|
		var mouseCtrl, snd;
		mouseCtrl = MouseX.kr(minFreq, maxFreq, \exponential, 0.1);
		snd = SinOsc.ar(mouseCtrl);
		Out.ar(out, Pan2.ar(snd, pan, amp)) //note pan here
	})
);
)

a = ~synthDefs[\SimpleSineMouse].note.play;
a.maxFreq_(2000);
a.free;

//also see:
"MouseY".openHelpFile
"MouseButton".openHelpFile

//--------------------------------------------------
// Live processing UGens
//--------------------------------------------------

//CAREFUL WITH FEEDBACK!!!


s.options.numOutputBusChannels = 32;
s.boot;

"In".openHelpFile;
"SoundIn".openHelpFile;

(
~synthDefs = CtkProtoNotes(
	SynthDef(\ringz, {|in = 0, out = 0, inAmp = 1, freq = 1, decay = 1, amp = 1|
		var inSig, outSig;
		inSig = In.ar(in, 1) * inAmp;
		outSig = Ringz.ar(inSig, freq, decay);
		Out.ar(out, outSig * amp);
	}),
	SynthDef(\ringMod, {|in = 0, out = 0, carAmp = 1, modAmp = 1, modFreq = 400, amp = 1|
		var modulator, carrier, result;
		modulator = SinOsc.ar(modFreq, mul: modAmp);
		carrier = In.ar(in, 1) * carAmp;
		result = modulator * carrier;
		Out.ar(out, result * amp);
	}),

	SynthDef(\bfPanner, {|in = 0, out = 0, amp = 1, azimuth = 0, elevation = 0|
		var inSig, bfSig;
		inSig = In.ar(in);
		bfSig = FoaPanB.ar(inSig, azimuth, elevation);
		Out.ar(out, bfSig * amp);
	}),

	SynthDef(\pitchshifter, {|in = 0, out = 0, ratio = 1, amp = 1|
		var inSig, outSig;
		inSig = In.ar(in, 1);
		outSig = PitchShift.ar(inSig, pitchRatio: ratio);
		Out.ar(out, outSig * amp);
	}),

	SynthDef(\delay, {|in = 0, out = 0, inAmp = 1, time = 1, feedback = 0.96 amp = 1|
		var inSig, outSig, localSnd;
		inSig = In.ar(in) * inAmp;
		localSnd = LocalIn.ar(1); //this is used for feedback; it introduces a delay of one control period - 64 samples by default
		outSig = DelayC.ar(inSig + localSnd, 5, time); //note max time
		LocalOut.ar(outSig * feedback);
		Out.ar(out, outSig * amp);
	}),
);
~micIn = s.options.numOutputBusChannels + 0;
)

a = ~synthDefs[\ringz].note.in_(~micIn).out_(0).freq_(400).decay_(0.2).inAmp_(-24.dbamp).play;
a.decay_(0.001)
a.freq_(CtkControl.lfo(SinOsc, 0.2, 300, 1200));
a.free

a = ~synthDefs[\ringMod].note.in_(~micIn).out_(0).modAmp_(1).modFreq_(100).play;
a.modAmp_(1);
a.modFreq_(40);
a.modFreq_(CtkControl.lfo(SinOsc, 0.2, 300, 1200));
a.free

a = ~synthDefs[\bfPanner].note.in_(~micIn).out_(2).azimuth_(CtkControl.lfo(SinOsc, 0.1, -pi, pi)).play; //note b-format output!
a.azimuth_(-pi/2);
a.elevation_(CtkControl.lfo(SinOsc, 0.1, -pi, pi));
a.free

a = ~synthDefs[\pitchshifter].note.in_(~micIn).out_(0).ratio_(1).play;
a.ratio_(1.6)
a.ratio_(0.375)
a.ratio_(CtkControl.lfo(SinOsc, 0.2, 0.5, 5));
a.free

a = ~synthDefs[\delay].note.in_(~micIn).inAmp_(0).time_(3).play;
a.inAmp_(1);
a.inAmp_(0);
a.time_(CtkControl.env(Env([3, 1], [2])));
a.time_(CtkControl.lfo(SinOsc, 0.1, 0.2, 4));
a.feedback_(0.96);
a.free




//--------------------------------------------------
// Live processing UGens with GUI
//--------------------------------------------------


(
var synths, notes;
var window, layout, sliders, buttons;
var masterVol, outputNumber, inputNumber, offsetIn;

//settings
masterVol = -3.dbamp; //dbamp here
outputNumber = 0; //0 - first audio output
inputNumber = 0; //first input

//initialization
offsetIn = s.options.numOutputBusChannels + inputNumber;
notes = IdentityDictionary.new;
sliders = IdentityDictionary.new;
buttons = IdentityDictionary.new;

//synths
synths = CtkProtoNotes(
	SynthDef(\ringz, {|in = 0, out = 0, inAmp = 1, freq = 1, decay = 1, amp = 1|
		var inSig, outSig;
		inSig = In.ar(in, 1) * inAmp;
		outSig = Ringz.ar(inSig, freq, decay);
		Out.ar(out, outSig * amp);
	}),
	SynthDef(\ringMod, {|in = 0, out = 0, carAmp = 1, modAmp = 1, modFreq = 400, amp = 1|
		var modulator, carrier, result;
		modulator = SinOsc.ar(modFreq, mul: modAmp);
		carrier = In.ar(in, 1) * carAmp;
		result = modulator * carrier;
		Out.ar(out, result * amp);
	}),

	SynthDef(\bfPanner, {|in = 0, out = 0, amp = 1, azimuth = 0, elevation = 0|
		var inSig, bfSig;
		inSig = In.ar(in);
		bfSig = FoaPanB.ar(inSig, azimuth, elevation);
		Out.ar(out, bfSig * amp);
	}),

	SynthDef(\pitchshifter, {|in = 0, out = 0, ratio = 1, amp = 1|
		var inSig, outSig;
		inSig = In.ar(in, 1);
		outSig = PitchShift.ar(inSig, pitchRatio: ratio);
		Out.ar(out, outSig * amp);
	}),

	SynthDef(\delay, {|in = 0, out = 0, inAmp = 1, time = 1, feedback = 0.96 amp = 1|
		var inSig, outSig, localSnd;
		inSig = In.ar(in) * inAmp;
		localSnd = LocalIn.ar(1); //this is used for feedback; it introduces a delay of one control period - 64 samples by default
		outSig = DelayC.ar(inSig + localSnd, 5, time); //note max time
		LocalOut.ar(outSig * feedback);
		Out.ar(out, outSig * amp);
	}),
);

//init window here, we'll need it afterwards
window = Window.new("live transform").front;
//create a layout which will space our buttons
layout = VLayout.new;
window.layout_(layout);


//setup notes, sliders and buttons
notes[\pitchShift1] = synths[\pitchshifter].note.in_(offsetIn).out_(outputNumber); //don't play yet

buttons[\pitchShift1] = Button(window).states_([[\pitchShift1], [\pitchShift1 ++ " running"]]);
buttons[\pitchShift1].action_({|buttonObject|
	buttonObject.value.postln;
	if(buttonObject.value.asBoolean, {
		//note obtaining amp from the slider
		notes[\pitchShift1].ratio_(sliders[\pitchShift1].value).play;
	}, {
		notes[\pitchShift1].free;
	});
});
sliders[\pitchShift1] = EZSlider(window, label: "pitch shift", controlSpec: ControlSpec(0.1, 4, \lin), initVal: 1, layout: \horz, unitWidth: 30);
sliders[\pitchShift1].action_({|thisSlider|
	notes[\pitchShift1].ratio_(thisSlider.value);
});

	//free buffers on close
window.onClose_({
	"stop all notes - through buttons".postln;
	buttons.do(_.valueAction_(0));
});

)

//--------------------------------------------------
// Recall Tasks with GUI (class 03.2)
//--------------------------------------------------


// LAB/Homework:
//extend your Tasks assignment:
//use functions to create tasks
//assign resulting tasks to be controlled by a button (start/stop)
//add at least one live processing function; on/off with a button, control using a slider

