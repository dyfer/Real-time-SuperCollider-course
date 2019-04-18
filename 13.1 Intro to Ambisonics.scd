//13
//intro to ambisonics

//first... intro to mid-side (MS) microphone technique

//ambisonic approacj is encoding a full sphere of sound into 4 channels
//DXARTS studios in Raitt (205, 117, 113) have a running decoder, so you can feed it with this 4-channel signal directly
//you can also decode the signal yourself into any number of speakers (or for headphone listening)


//---------------
// simple ambisonics panner
//--------------

//this uses external decoder (e.g. rooms 205/117/113)

s.options.numOutputBusChannels_(8);
s.reboot;

//radians vs degrees
0.raddeg;
pi.raddeg;
pi
1.57.raddeg;
0.degrad;
90.degrad;
180.degrad;

(
var synth, note, window, azKnob, elKnob;
s.waitForBoot({
	synth = CtkSynthDef(\bfNoise, {arg out = 2, amp = 0.5, azimuth = 0, elevation = 0; //azimuth and elevation in radians
		Out.ar(out, FoaPanB.ar(PinkNoise.ar(amp), azimuth, elevation));
	});
	s.sync; //so the synth is ready before we call it
	note = synth.note.out_(2).play; //

	window = Window.new.front;
	window.onClose_({note.free});

	azKnob = EZKnob(window, 60@60, \azimuth, ControlSpec(-180, 180, default: 0), {|knob| note.azimuth_(knob.value.degrad.neg)});
	elKnob = EZKnob(window, 60@60, \elevation, ControlSpec(-90, 90, default: 0), {|knob| note.elevation_(knob.value.degrad)});
	window.layout_(
		HLayout(
			VLayout(azKnob.labelView, azKnob.knobView, azKnob.numberView),
			VLayout(elKnob.labelView, elKnob.knobView, elKnob.numberView),
		);
	);
});
)


//more advanced examples (including HRTF decoding for headphones):
"Introducing the Ambisonic Toolkit".openHelpFile;


//---------------
// simple ambisonics with switchable decoding (stereo, 6-channel, or exteranal decoder
//--------------

FoaDecoderMatrix.openHelpFile;

(
var synths, notes, window, azKnob, elKnob;
var decoderType, decoderMatrix;
var mainVolume;
var mainGroup, decGroup;
var bfBus;

mainVolume = 0.dbamp;
decoderType = \uhj; //possible \uhj - stereo, \hex - 6-channel, \bf - b-format directly to external decoder, \hrtf - for headphone listning

notes = IdentityDictionary.new;

s.waitForBoot({

	if(decoderType == \hrtf, {
		decoderMatrix = FoaDecoderKernel.newSpherical; //prepare internal buffers for hrtf decoder
		s.sync;
	});

	synths = CtkProtoNotes(
		SynthDef(\bfNoise, {arg out = 2, amp = 4, azimuth = 0, elevation = 0; //azimuth and elevation in radians
			Out.ar(out, FoaPanB.ar(
				PinkNoise.ar(amp) * Impulse.ar(2).lagud(0, 0.5),
				azimuth, elevation));
		}),
		SynthDef(\decoder, {arg in = 0, out = 0; //azimuth and elevation in radians
			var sndIn, sndOut;
			sndIn = In.ar(in, 4); //4-channel bus input
			decoderType.switch(
				\uhj, {sndOut = B2UHJ.ar(sndIn[0], sndIn[1], sndIn[2])},
				\bf, {sndOut = sndIn},
				\hex, {sndOut = FoaDecode.ar(sndIn, FoaDecoderMatrix.newPanto(6, k: 'energy')).at([0, 5, 4, 3, 2, 1])},
				\hrtf, {sndOut = FoaDecode.ar(sndIn, decoderMatrix)}
			);
			Out.ar(out, sndOut.clip(-1, 1) * mainVolume);
		})
	);

	mainGroup = CtkGroup.play;
	s.sync;
	decGroup = CtkGroup.play(addAction: \tail);

	bfBus = CtkAudio.new(4);

	s.sync; //so the synth is ready before we call it
	// notes[\dec] = synths[\decoder].note.in_(bfBus).out_(0).play; //start decider
	// s.sync;
	// notes[\src] = synths[\bfNoise].note(target: notes[\dec], addAction:  \before).out_(bfBus).play;
	notes[\dec] = synths[\decoder].note(target: decGroup).in_(bfBus).out_(0).play; //start decider
	notes[\src] = synths[\bfNoise].note(target: mainGroup).out_(bfBus).play;

	~src = notes[\src];

	window = Window.new.front;

	azKnob = EZKnob(window, nil, \azimuth, ControlSpec(-180, 180, default: 0), {|knob| notes[\src].azimuth_(knob.value.degrad.neg)});
	elKnob = EZKnob(window, nil, \elevation, ControlSpec(-90, 90, default: 0), {|knob| notes[\src].elevation_(knob.value.degrad)});
	window.layout_(
		HLayout(
			VLayout(azKnob.labelView, azKnob.knobView, azKnob.numberView),
			VLayout(elKnob.labelView, elKnob.knobView, elKnob.numberView),
		);
	);

	window.onClose_({
		notes.do({arg thisNote;
			thisNote.free;
		});
		mainGroup.free;
		decGroup.free;
		bfBus.free;
		if(decoderMatrix.notNil, {
			decoderMatrix.free;
		}); //free the kernel
	});

	s.plotTree;
});
)

~src.amp_(12)
~src.amp_(48)
