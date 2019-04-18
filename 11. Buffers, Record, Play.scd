//Buffers - record, play, log information

//------------------------------------------------------------
// --------------------   Record & Play - basic   -----------------
//------------------------------------------------------------

(
s.waitForBoot({
	~synths = CtkProtoNotes(
		SynthDef(\recorder, {arg in = 0, buffer = 0;
			var inSig;
			inSig = In.ar(in, 1);
			RecordBuf.ar(inSig, buffer);
		}),
		SynthDef(\player, {arg out = 0, buffer = 0, playRate = 1, amp = 1;
			var outSig;
			outSig = PlayBuf.ar(1, buffer, playRate);
			Out.ar(out, outSig * amp);
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


//------------------------------------------------------------
// --------------------   Record & Play - amplitudeTrigger   --------
//------------------------------------------------------------

(
s.waitForBoot({
	~synths = CtkProtoNotes(
		SynthDef(\recorderTrig, {arg in = 0, buffer = 0, ampFollowerAtt = 0, ampFollowerRel = 0.2, trigAmpStart = 0.5, trigAmpStop = 0.2;
			var inSig, amplitude, trigger;
			inSig = In.ar(in, 1);
			amplitude = Amplitude.kr(inSig, ampFollowerAtt, ampFollowerRel);
			trigger = Schmidt.kr(amplitude, trigAmpStop, trigAmpStart);
			RecordBuf.ar(inSig, buffer, run: trigger);
			SendReply.kr(trigger, '/trigger', trigger); //when rec starts
			SendReply.kr(trigger.neg + 1, '/trigger', trigger); //when rec stops
		}),
		SynthDef(\player, {arg out = 0, buffer = 0, playRate = 1, amp = 1;
			var outSig;
			outSig = PlayBuf.ar(1, buffer, playRate);
			Out.ar(out, outSig * amp)
		})
	);

	~someBuffer = CtkBuffer(size: s.sampleRate * 10 /*10 seconds*/, numChannels: 1, server: s).load; //remember to .load!
	s.sync; //wait for the buffer to load on the server; this is possible since we're in the .waitForBoot routine

	~responder = OSCdef(\trig, {|val|
		val.postln;
	}, '/trigger');
});
)

s.plotTree;
s.meter;
~someBuffer.plot;

//record
~recNote = ~synths[\recorderTrig].note.in_(s.options.numOutputBusChannels + 0).buffer_(~someBuffer).trigAmpStart_(-12.dbamp).trigAmpStop_(-36.dbamp).ampFollowerRel_(2).play;
~recNote.free;

~someBuffer.plot;


//play
~playNote = ~synths[\player].note.out_(0).buffer_(~someBuffer).play;
~playNote.free;


//free when done!
~someBuffer.free; ~responder.free;



//------------------------------------------------------------
// --------   Record & Play - amplitudeTrigger with time log   --------
//------------------------------------------------------------

(
~startTimes = List.new;
s.waitForBoot({
	~synths = CtkProtoNotes(
		SynthDef(\recorderTrigTimeLog, {arg in = 0, buffer = 0, ampFollowerAtt = 0, ampFollowerRel = 0.2, trigAmpStart = 0.5, trigAmpStop = 0.2;
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
			RecordBuf.ar(inSig, buffer, run: trigger);
			SendReply.kr(trigger, '/trigger', [trigger, currentTime, currentFrame]); //when rec starts
			SendReply.kr(inverseTrigger, '/trigger', [trigger, currentTime, currentFrame]); //when rec stops
		}),
		SynthDef(\player, {arg out = 0, buffer = 0, playRate = 1, amp = 1, startPos = 0;
			var outSig;
			outSig = PlayBuf.ar(1, buffer, playRate, startPos: startPos * BufSampleRate.kr(buffer));
			Out.ar(out, outSig * amp)
		})
	);

	~someBuffer = CtkBuffer(size: s.sampleRate * 10 /*10 seconds*/, numChannels: 1, server: s).load; //remember to .load!
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

s.plotTree;
s.meter;
~someBuffer.plot;

//record
~recNote = ~synths[\recorderTrigTimeLog].note.in_(s.options.numOutputBusChannels + 0).buffer_(~someBuffer).trigAmpStart_(-12.dbamp).trigAmpStop_(-36.dbamp).ampFollowerRel_(2).play;
~recNote.free;

~someBuffer.plot;

~startTimes.postln;

//play
~playNote = ~synths[\player].note.out_(0).buffer_(~someBuffer).play;
~playNote.free;

//play from a concrete point
~playNote = ~synths[\player].note.out_(0).buffer_(~someBuffer).startPos_(~startTimes[2][0]).play;
~playNote.free

(
~playEvent = {arg eventNumber;
	"Playing event ".post; eventNumber.postln;
	"Start/stop time: ".post; ~startTimes[eventNumber].postln;
	~playNote = ~synths[\player].note(0, ~startTimes[eventNumber][1] - ~startTimes[eventNumber][0])
	.out_(0).buffer_(~someBuffer).startPos_(~startTimes[eventNumber][0]).play;
};
)

~playEvent.(5);

Blip



//free when done!
~someBuffer.free; ~responder.free;

y = List.new
y.add(232)
y.size - 1

y.lastIndex

