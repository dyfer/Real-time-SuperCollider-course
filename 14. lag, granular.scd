//14


// ----------------------------------------
// ----- smoothing out control signals --------
// ----------------------------------------

//instroducing lag
//inside the synth: value.lag, value.lagUD, value.lag2, value.lag2UD, value.lag3, value.lag3UD
//same as Lag.kr(value)
//they take time as argument
//help:
"Lag".openHelpFile;
"Lag2".openHelpFile;
"Lag3".openHelpFile;
"VarLag".openHelpFile;


//slider example
(
var window, layout, sliders, synths, note, bus, resp, respPath, labels;

labels = [\input, \lag, \lag2, \lag3, \lagud, \lag2ud, \lag3ud, \varlag];

respPath='/lagged';

s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\lags, {arg inVal = 0, lagTime = 1, lagTimeU = 1, lagTimeD = 3, curve = 0;
			var trig;
			// inVal = In.kr(in, 1);
			trig = Impulse.kr(30);
			SendReply.kr(trig, respPath, [
				inVal.lag(lagTime),
				inVal.lag2(lagTime),
				inVal.lag3(lagTime),
				inVal.lagud(lagTimeU, lagTimeD),
				inVal.lag2ud(lagTimeU, lagTimeD),
				inVal.lag3ud(lagTimeU, lagTimeD),
				inVal.varlag(lagTime, curve),
			]
			)
		})
	);

	s.sync; //sync before playing

	note = synths[\lags].note.play;
	~note = note; //to set something later

	window = Window.new.front;
	layout = HLayout.new;
	window.layout = layout; //assigning layout to the window
	sliders = 8.collect({|inc|
		var thisSlider;
		thisSlider = Slider.new;
		layout.add(
			VLayout(
				thisSlider,
				StaticText.new.string_(labels[inc])
			)
		);
		thisSlider;
	});

	sliders[0].action_({arg sl;
		// bus.setSynchronous(sl.value)
		note.inVal_(sl.value);
	}); //first slider changes values

	resp = OSCdef(\lags, {arg values;
		var sliderValues;
		// values.postln;
		sliderValues = values[3..];
		{
			sliderValues.do({|thisVal, inc|
				sliders[inc+1].value = thisVal
			});
		}.defer;
	}, respPath);

	//free:
	window.onClose_({
		note.free;
		resp.free;
	});
});

)


//slider example with sinewave
(
var window, layout, sliders, synths, note, bus, resp, respPath, labels;

labels = [\input, \lag, \lag2, \lag3, \lagud, \lag2ud, \lag3ud, \varlag];

respPath='/lagged';


s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\lags, {arg inVal = 0, lagTime = 1, lagTimeU = 2, lagTimeD = 0.5, curve = 0, amp = 0.063, out = 0;
			var trig;
			// inVal = In.kr(in, 1);
			trig = Impulse.kr(30);
			Out.ar(out, SinOsc.ar(500 * ([
				inVal,
				inVal.lag(lagTime),
				inVal.lag2(lagTime),
				inVal.lag3(lagTime),
				inVal.lagud(lagTimeU, lagTimeD),
				inVal.lag2ud(lagTimeU, lagTimeD),
				inVal.lag3ud(lagTimeU, lagTimeD),
				inVal.varlag(lagTime, curve),
			] + 1), 0, amp).sum.dup(2));
			SendReply.kr(trig, respPath, [
				inVal.lag(lagTime),
				inVal.lag2(lagTime),
				inVal.lag3(lagTime),
				inVal.lagud(lagTimeU, lagTimeD),
				inVal.lag2ud(lagTimeU, lagTimeD),
				inVal.lag3ud(lagTimeU, lagTimeD),
				inVal.varlag(lagTime, curve),
			]
			)
		})
	);

	s.sync; //sync before playing

	note = synths[\lags].note.play;
	~note = note; //to set something later

	window = Window.new.front;
	layout = HLayout.new;
	window.layout = layout; //assigning layout to the window
	sliders = 8.collect({|inc|
		var thisSlider;
		thisSlider = Slider.new;
		layout.add(
			VLayout(
				thisSlider,
				StaticText.new.string_(labels[inc])
			)
		);
		thisSlider;
	});

	sliders[0].action_({arg sl;
		note.inVal_(sl.value);
	}); //first slider changes values

	resp = OSCdef(\lags, {arg values;
		var sliderValues;
		// values.postln;
		sliderValues = values[3..];
		{
			sliderValues.do({|thisVal, inc|
				sliders[inc+1].value = thisVal
			});
		}.defer;
	}, respPath);

	//free:
	window.onClose_({
		note.free;
		resp.free;
	});
});

)

//slider example with trigger
(
var window, layout, sliders, synths, note, bus, resp, respPath, labels;

labels = [\input, \lag, \lag2, \lag3, \lagud, \lag2ud, \lag3ud, \varlag];

respPath='/lagged';


s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\lags, {arg inVal = 0, lagTime = 1, lagTimeU = 0.1, lagTimeD = 2, curve = 0, amp = 0.5, out = 0, trigLo = 0.2, trigHi = 0.8;
			var trig;
			trig = Impulse.kr(30);
			Out.ar(out, PinkNoise.ar(amp).dup(2) * Schmidt.kr( //uncomment ONE LINE at a time
				// inVal,
				// inVal.lag(lagTime),
				// inVal.lag2(lagTime),
				// inVal.lag3(lagTime),
				// inVal.lagud(lagTimeU, lagTimeD),
				// inVal.lag2ud(lagTimeU, lagTimeD),
				inVal.lag3ud(lagTimeU, lagTimeD),
				// inVal.varlag(lagTime, curve),
				trigLo, trigHi)
			);
			SendReply.kr(trig, respPath, [
				inVal.lag(lagTime),
				inVal.lag2(lagTime),
				inVal.lag3(lagTime),
				inVal.lagud(lagTimeU, lagTimeD),
				inVal.lag2ud(lagTimeU, lagTimeD),
				inVal.lag3ud(lagTimeU, lagTimeD),
				inVal.varlag(lagTime, curve),
			]
			)
		})
	);

	s.sync; //sync before playing

	note = synths[\lags].note.play;
	~note = note; //to set something later

	window = Window.new.front;
	layout = HLayout.new;
	window.layout = layout; //assigning layout to the window
	sliders = 8.collect({|inc|
		var thisSlider;
		thisSlider = Slider.new;
		layout.add(
			VLayout(
				thisSlider,
				StaticText.new.string_(labels[inc])
			)
		);
		thisSlider;
	});

	sliders[0].action_({arg sl;
		note.inVal_(sl.value);
	}); //first slider changes values

	resp = OSCdef(\lags, {arg values;
		var sliderValues;
		// values.postln;
		sliderValues = values[3..];
		{
			sliderValues.do({|thisVal, inc|
				sliders[inc+1].value = thisVal
			});
		}.defer;
	}, respPath);

	//free:
	window.onClose_({
		note.free;
		resp.free;
	});
});

)


// ----------------------------------------
// ----- granular synthesis from input signal ----
// ----------------------------------------

(
s.waitForBoot({
	~synths = CtkProtoNotes(
		SynthDef(\recorder, {arg in = 0, buffer = 0;
			var inSig;
			inSig = In.ar(in, 1);
			RecordBuf.ar(inSig, buffer);
		}),
		SynthDef(\player, {arg out = 0, buffer = 0, playRateLo = 0.5, playRateHi = 1.5, amp = 1, pan = 0, gate = 1;
			var outSig, env;
			env = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
			outSig = GrainBuf.ar(
				2, //number of channels for panning
				Impulse.kr(10), //trigger; on each change of the signal from 0 to >0, new grain is being produced
				0.1, //grain duration
				buffer, //monophonic buffer
				LFNoise1.kr.range(playRateLo, playRateHi), //playback rate
				LFNoise2.kr(0.1).range(0, 1), //position in the file (0-1)
				4, //interpolation - here cubic for best sound (but more computationally expensive)
				pan //panning
			);
			Out.ar(out, outSig * amp * env);
		})
	);

	~someBuffer = CtkBuffer(size: s.sampleRate * 10 /*10 seconds*/, numChannels: 1, server: s).load; //remember to .load!
	s.sync; //wait for the buffer to load on the server; this is possible since we're in the .waitForBoot routine
});
)

s.plotTree;
s.meter;
~someBuffer.plot;

//record
~recNote = ~synths[\recorder].note.in_(s.options.numOutputBusChannels + 0).buffer_(~someBuffer).play;
~recNote.free;

~someBuffer.plot;


//play
~playNote = ~synths[\player].note.out_(0).buffer_(~someBuffer).play;
~playNote.free;

//saving
~someBuffer.write(path: "mySound.wav".resolveRelative, headerFormat: 'wav', sampleFormat: 'float');


//free when done!
~someBuffer.free;


// --------------------------------------------------------------------------------
// ----- granular synthesis from input signal - advanced, keeping track of endposition ----
// --------------------------------------------------------------------------------

(
~responder.free; ~someBuffer.free; ~posBus.free; ~playNote.free; ~recNote.free;
~startTimes = List.new;
s.waitForBoot({
	~synths = CtkProtoNotes(
		SynthDef(\recorderTrigTimeLog, {arg in = 0, buffer = 0, ampFollowerAtt = 0, ampFollowerRel = 0.2, trigAmpStart = 0.5, trigAmpStop = 0.2, curPosOut = 0;
			var inSig, amplitude, trigger, currentFrame, currentTime, inverseTrigger, lastFrameValue;
			inSig = In.ar(in, 1);
			amplitude = Amplitude.kr(inSig, ampFollowerAtt, ampFollowerRel);
			amplitude = Amplitude.kr(inSig, ampFollowerAtt, ampFollowerRel);
			trigger = Schmidt.kr(amplitude, trigAmpStop, trigAmpStart);
			inverseTrigger = trigger.neg + 1;
			lastFrameValue = Latch.kr(LocalIn.kr(1), inverseTrigger);
			currentFrame = Phasor.kr(trigger, 1, 0, BufFrames.kr(buffer), lastFrameValue); //timer to report current sample
			LocalOut.kr(currentFrame);
			currentTime = currentFrame / ControlRate.ir; //convert to time; ControlDur is inverse of ControlRate
			Out.kr(curPosOut, Gate.kr(currentTime, trigger));
			RecordBuf.ar(inSig, buffer, run: trigger);
			SendReply.kr(trigger, '/trigger', [trigger, currentTime, currentFrame]); //when rec starts
			SendReply.kr(inverseTrigger, '/trigger', [trigger, currentTime, currentFrame]); //when rec stops
		}),

		SynthDef(\player, {arg out = 0, buffer = 0, playRateLo = 0.5, playRateHi = 1.5, amp = 1, pan = 0, gate = 1, curPosIn = 0;
			var outSig, env, curPosSig, trig, pos;
			curPosSig = In.kr(curPosIn, 1);
			env = EnvGen.kr(Env([0, 1, 0], [1, 1], \sin, 1), gate, doneAction: 2);
			trig = Impulse.kr(10);
			pos = TRand.kr(0, (((curPosSig-0.1)/BufDur.kr(buffer)) ).clip(0, 1), trig);//limit current position, subtract current grain duration
			outSig = GrainBuf.ar(
				2, //number of channels for panning
				trig, //trigger; on each change of the signal from 0 to >0, new grain is being produced
				0.1,  //grain duration
				buffer, //monophonic buffer
				LFNoise1.kr.range(playRateLo, playRateHi), //playback rate
				pos, //position in the file (0-1)
				4, //interpolation - here cubic for best sound (but more computationally expensive)
				pan //panning
			);
			Out.ar(out, outSig * amp * env);
		})
	);

	~posBus = CtkControl.play(1);

	~someBuffer = CtkBuffer(size: s.sampleRate * 30 /*30 seconds*/, numChannels: 1, server: s).load; //remember to .load!
	s.sync; //wait for the buffer to load on the server; this is possible since we're in the .waitForBoot routine

	~responder = OSCdef(\trig, {|val|
		var trigVal, curTime;
		val.postln;
		trigVal = val[3];
		curTime = val[4];
		if(trigVal == 1, {
			~startTimes.add([curTime, 0]); //0 as end time
		}, {
			if(~startTimes.lastIndex.notNil, {
				~startTimes[~startTimes.lastIndex][1] = curTime;
			});
		});
	}, '/trigger');
});
)

//record
~recNote = ~synths[\recorderTrigTimeLog].note.in_(s.options.numOutputBusChannels + 0).buffer_(~someBuffer).trigAmpStart_(-12.dbamp).trigAmpStop_(-36.dbamp).ampFollowerRel_(2).curPosOut_(~posBus).play;
//play
~playNote = ~synths[\player].note.out_(0).buffer_(~someBuffer).curPosIn_(~posBus).play;

//check current position
s.getControlBusValue(~posBus.bus);


~someBuffer.plot;

~playNote.free;

~responder.free; ~someBuffer.free; ~posBus.free; ~playNote.free; ~recNote.free;


s.plotTree;
s.meter;
s.scope
~someBuffer.plot;





