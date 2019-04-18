//--------------------------------------------------
// Server-language communication; Machine listening;
//--------------------------------------------------

//sound examples first!

// Server.killAll // you're getting "Exception in World_OpenUDP: unable to bind udp socket" error


//--------------------------------------------------
// Sending information from the Synth to the Lang
//--------------------------------------------------

//there is SendTrig and SendReply
//SendTrig - send single value, identified by an ID
//SendReply - sends array of values, identified by an ID and custom address/name

//looking into all incoming OSC messages
OSCFunc.trace(true);
OSCFunc.trace(false); //turn off


//--------
// SendTrig
//--------
s.boot;
s.options.sampleRate = 48000;
//amplitude < 0.8; //possible synth trigger
(
s.waitForBoot({
	~synth = CtkSynthDef(\sendTrigTest, {|id = 0|
		var trig, value;
		trig = Impulse.kr(2);
		// trig.poll(10, \myImpulse);
		// trig = Dust.kr(2);//try that as well - random
		value = TRand.kr(0, 1, trig); //getting values on trig...
		SendTrig.kr(trig, id, value);
	});

	// register to receive this message
	~resp = OSCdef(\defName, { arg msg, time;
		[time, msg].postln;
		"id: ".post; msg[2].postln;
		"value: ".post; msg[3].postln;
	},'/tr'); //responding to '/tr' message '/tr' \otherSymbols
	//note OSCdef not OSCFunc; OSCdef will OVERWRITE any previous responders associated with \defName symbol, so it's less problematic if you forget to free it before running the code again
});
);

~synth.note(0, 10).play; //play for 10 seconds, see posting

~synth.note(0, 10).id_(123).play; //play for 10 seconds, different ID

~resp.free; //important! use cmdPeriod or window.onClose to evaluate that;



//--------
// SendReply
//--------

//can send multiple values!

(
var replyName;

replyName = '/myReply'; //you can't change that when you call the synth, but you can have various synth definition with various names if desired; ID will sill probably be useful; not it needs to start with a forward slash

~synth = CtkSynthDef(\sendReplyTest,{|id = 0|
	var trig, values;
	trig = Impulse.kr(2);
	// trig = Dust.kr(2);//try that as well
	values = [TRand.kr(0, 1, trig), TRand.kr(0, 1, trig), TRand.kr(0, 1, trig), TRand.kr(0, 1, trig)]; //getting and array of random values on trig...
	SendReply.kr(trig, replyName, values, id);
});

// register to receive this message
~resp2 = OSCdef(replyName, { arg msg, time; //we can safely assume we want only one responder per replyName, so instead of creating a special name for it, we can use the reply sybol for it
	// [time, msg].postln;
	"id: ".post; msg[2].postln;
	"values: ".post; msg[3..].round(0.001).postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
}, replyName); //responding to '/tr' message
)

~synth.note(0, 10).play; //play for 10 seconds, see posting

~synth.note(0, 10).id_(123).play; //play for 10 seconds, different ID

~resp2.free; //important! if you don't do that, you'll run into trouble! use cmdPeriod or window.onClose to evaluate that




//use ctkcontrol

//--------------------------------------------------
// Extracting musical features
//--------------------------------------------------
s.quit;
s.options.numOutputBusChannels = 16;
s.options.numInputBusChannels = 16;
s.boot
s.meter;


~inputNumber = 0; //offset into input bus
//-------
//onsets
//-------
(
var replyName;

~inputNumber = 0; //offset into input bus

replyName = '/myReply';

~synth = CtkSynthDef(\onsetsTest,{|in = 0, threshold = 0.5, id = 0|
	var trig, values, inSig;
	var localbuf, chain;
	inSig = In.ar(in, 1);

	localbuf = LocalBuf(512);
	chain = FFT(localbuf, inSig);

	trig = Onsets.kr(chain, threshold); //here we detect onsets

	values = 0; //we don't have anything to send - yet
	SendReply.kr(trig, replyName, values, id);
});

// register to receive this message
~resp = OSCdef(replyName, { arg msg, time; //we can safely assume we want only one responder per replyName, so instead of creating a special name for it, we can use the reply sybol for it
	[time, msg].postln;
	"id: ".post; msg[2].postln;
	"values: ".post; msg[3..].postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
}, replyName); //responding to '/tr' message
)

~synth.note(0, 10).in_(s.options.numOutputBusChannels + ~inputNumber).threshold_(0.5).play; //play for 10 seconds, see posting

~resp.free; //important! if you don't do that, you'll run into trouble! use cmdPeriod or window.onClose to evaluate that

//---------
//pitch and amplitude
//---------
(
var replyName;

~inputNumber = 0; //offset into input bus

replyName = '/myReply';

~synth = CtkSynthDef(\pitchAmpTest,{|in = 0, threshold = 0.93, id = 0, att = 0.01, rel = 0.01|
	var trig, freq, hasFreq, amplitude, inSig;
	// var localbuf, chain;
	inSig = In.ar(in, 1);

	trig = Impulse.kr(10); //let's repor continuosly 10 times per second
	#freq, hasFreq = Tartini.kr(inSig, threshold);
	amplitude = Amplitude.kr(inSig, att, rel); //also see Lag ugens for smoothing

	// values = 0; //we don't have anything to send - yet
	SendReply.kr(trig, replyName, [freq, hasFreq, amplitude], id);
});

// register to receive this message
~resp = OSCdef(replyName, { arg msg, time; //we can safely assume we want only one responder per replyName, so instead of creating a special name for it, we can use the reply sybol for it
	// [time, msg].postln;
	// "id: ".post; msg[2].postln;
	// "values: ".post; msg[3..].postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
	postf("freq: %, hasFreq: %, amplitude (dB): %\n", msg[3].round(0.01), msg[4].round(0.01), msg[5].ampdb.round(0.01)/*convert amp to dB*/); //see String helpfile for postf explanation; also note newline symbol at the end (\n); values are rounded for posting
}, replyName); //responding to '/tr' message
)

~synth.note(0, 10).in_(s.options.numOutputBusChannels + ~inputNumber).play; //play for 10 seconds, see posting

~resp.free; //important! if you don't do that, you'll run into trouble! use cmdPeriod or window.onClose to evaluate that



//---------
//spectral flatness and centroid
//---------
(
var replyName;

~inputNumber = 0; //offset into input bus

replyName = '/myReply';

~synth = CtkSynthDef(\spectrTest,{|in = 0, threshold = 0.93, id = 0, att = 0.01, rel = 0.01|
	var trig, flatness, centroid, inSig;
	var localbuf, chain;
	inSig = In.ar(in, 1);

	localbuf = LocalBuf(512);
	chain = FFT(localbuf, inSig);

	trig = Impulse.kr(10); //let's repor continuosly 10 times per second
	centroid = SpecCentroid.kr(chain);
	flatness = SpecFlatness.kr(chain);

	// values = 0; //we don't have anything to send - yet
	SendReply.kr(trig, replyName, [centroid, flatness], id);
});

// register to receive this message
~resp = OSCdef(replyName, { arg msg, time; //we can safely assume we want only one responder per replyName, so instead of creating a special name for it, we can use the reply sybol for it
	// [time, msg].postln;
	// "id: ".post; msg[2].postln;
	// "values: ".post; msg[3..].postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
	postf("spectral centroid: %, flatness: %\n", msg[3].round(0.01), msg[4].round(0.001)); //see String helpfile for postf explanation; also note newline symbol at the end (\n); values are rounded for posting
}, replyName); //responding to '/tr' message
)

~synth.note(0, 10).in_(s.options.numOutputBusChannels + ~inputNumber).play; //play for 10 seconds, see posting

~resp.free; //important! if you don't do that, you'll run into trouble! use cmdPeriod or window.onClose to evaluate that




//---------
//musical example: onsets trigger synth, amplitude and pitch
//---------
(
var replyName, lastNote, playerSynth;

~inputNumber = 0; //offset into input bus

replyName = '/myReply';

~synth = CtkSynthDef(\spectrTest,{|in = 0, threshold = 0.93, id = 0, att = 0.01, rel = 0.01, onsetThreshold = 0.5, freqOut = 0, ampOut = 0, hasFreqThreshold = 0.8|
	var trig, freq, hasFreq, amplitude, inSig;
	var localbuf, chain;
	inSig = In.ar(in, 1);

	localbuf = LocalBuf(256);
	chain = FFT(localbuf, inSig);

	// trig = Impulse.kr(10); //let's repor continuosly 10 times per second
	trig = Onsets.kr(chain, onsetThreshold); //here we detect onsets
	#freq, hasFreq = Tartini.kr(inSig, threshold);
	amplitude = Amplitude.kr(inSig, att, rel); //also see Lag ugens for smoothing

	// amplitude = (hasFreq > hasFreqThreshold) * amplitude;
	// hasFreq.poll(2, \hasFreq);

	// values = 0; //we don't have anything to send - yet
	SendReply.kr(trig, replyName, freq, id); //send freq at the time of onset

	//output for continuous signals
	Out.kr(freqOut, freq);
	Out.kr(ampOut, amplitude);
});

playerSynth = CtkSynthDef(\sawPlayer, {|out = 0, amp = 1, freq = 400, freqMul = 1, ampLagU = 0.01, ampLagD = 1, pan = 0, gate = 1, att = 0.1, rel = 1|
	var sig, env;
	env = EnvGen.kr(Env([0,1,0], [att, rel], \sin, 1), gate);
	sig = Saw.ar(freq * freqMul, amp.lag3ud(ampLagU, ampLagD)); //see Lag3UD help
	Out.ar(out, Pan2.ar(sig, pan) * env);
});


~pitchBus = CtkControl.play;
~ampBus = CtkControl.play;


// register to receive this message
~resp = OSCdef(replyName, { arg msg, time;
	var freq;
	// [time, msg].postln;
	// "id: ".post; msg[2].postln;
	"values: ".post; msg[3..].postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
	freq = msg[3];
	// postf("spectral centroid: %, flatness: %\n", msg[3].round(0.01), msg[4].round(0.001)); //see String helpfile for postf explanation; also note newline symbol at the end (\n); values are rounded for posting
	lastNote.free;
	lastNote = playerSynth.note(0, 10).out_(0).amp_(~ampBus).freq_(~pitchBus).play; //free after 10s anyway
	// lastNote = playerSynth.note(0, 20).out_(0).amp_(~ampBus).freq_(~pitchBus).ampLagD_(5).freqMul_(3.2).play; //try me
	// lastNote = playerSynth.note(0, 20).out_(0).amp_(~ampBus).freq_(freq).ampLagD_(5).freqMul_(3.2).play; //try me
}, replyName); //responding to '/tr' message
)

~synth.note(0, 10).in_(s.options.numOutputBusChannels + ~inputNumber).freqOut_(~pitchBus).ampOut_(~ampBus).rel_(2).play; //play for 10 seconds, see posting


[~resp, ~pitchBus, ~ampBus].do(_.free); //free everything


//other ugens to explore (see helpfiles):
//SpecPcile
//Loudness


//---------
//musical example: onsets trigger harmonizer
//---------
(
var replyName, lastNote, playerSynth;

~inputNumber = 0; //offset into input bus

replyName = '/myReply';

~synth = CtkSynthDef(\spectrHarm,{|in = 0, threshold = 0.93, id = 0, att = 0.01, rel = 0.01, onsetThreshold = 0.5, freqOut = 0, ampOut = 0, out = 0|
	var trig, freq, hasFreq, amplitude, inSig;
	var localbuf, chain;
	var outSig;

	inSig = In.ar(in, 1);

	// inSig = A2K.kr(inSig);
	// inSig = K2A.ar(inSig);

	localbuf = LocalBuf(512);
	chain = FFT(localbuf, inSig);
	trig = Onsets.kr(chain, onsetThreshold); //here we detect onsets

	outSig = 3.collect({
		PitchShift.ar(inSig, 0.2, TRand.kr(0, 7, trig).round(1).midiratio)
	}).sum;

	// values = 0; //we don't have anything to send - yet
	SendReply.kr(trig, replyName, freq, id); //send freq at the time of onset

	Out.ar(out, Pan2.ar(outSig));
	//output for continuous signals
	// Out.kr(freqOut, freq);
	// Out.kr(ampOut, amplitude);
});

)

~synth.note(0, 10).in_(s.options.numOutputBusChannels + ~inputNumber).out_(0).play; //play for 10 seconds, see posting
