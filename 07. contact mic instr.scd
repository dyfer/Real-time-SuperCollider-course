ServerOptions

s.options.hardwareBufferSize = 64; //setting for lower latency
s.boot
s.quit
s.reboot


//--------
// SendReply
//--------

//can send multiple values!

(
var replyName;

replyName = '/myReply'; //you can't change that when you call the synth, but you can have various synth definition with various names if desired; ID will sill probably be useful; not it needs to start with a forward slash

~ctrlBus = Bus.new(\control, numChannels: 1);

~synth = CtkProtoNotes(
	SynthDef(\sendReplyTest, {arg id = 0, inbus = 0, ampAtt = 0.01, ampRel = 0.01, outbus = 0, threshold = 0.5;
		var inSig, amplitude, trig, values;
		inSig = In.ar(inbus, 1);
		amplitude = Amplitude.kr(inSig, ampAtt, ampRel);
		trig = amplitude > threshold;
		// trig = Dust.kr(2);//try that as well
		// values = [TRand.kr(0, 1, trig), TRand.kr(0, 1, trig), TRand.kr(0, 1, trig), TRand.kr(0, 1, trig)]; //getting and array of random values on trig...
		SendReply.kr(trig, replyName, amplitude, id);
		Out.kr(outbus, trig);
	}),
	SynthDef(\percNoise, {arg outbus = 0, amp = 1, att = 0.01, rel = 1;
		var sig, env;
		sig = WhiteNoise.ar;
		env = EnvGen.kr(Env.perc(att, rel, amp), doneAction: 2);
		Out.ar(outbus, Pan2.ar(sig * env));
	})
);

// register to receive this message
~resp2 = OSCdef(replyName, { arg msg, time;
	var amplitude;
	[time, msg].postln;
	// "id: ".post; msg[2].postln;
	// "values: ".post; msg[3..].round(0.001).postln; //syntactical shortcut for "copy from 3rd member till the end of an array"
	amplitude = msg[3];
	~synth[\percNoise].note.amp_(amplitude).play;
}, replyName); //responding to '/tr' message
)

~ctrlBus.scope;

~note = ~synth[\sendReplyTest].note.inbus_(s.options.numOutputBusChannels + 0).outbus_(~ctrlBus).ampAtt_(0).ampRel_(0.1).threshold_(-39.dbamp).play; //play for 10 seconds, see posting

~note.free;
~note.threshold_(-36.dbamp)

s.meter
x = {PinkNoise.ar}.play
x.free

~synth.note(0, 10).play; //play for 10 seconds, see posting


~ctrlBus.free;

~synth.note(0, 10).id_(123).play; //play for 10 seconds, different ID

~resp2.free; //important! if you don't do that, you'll run into trouble! use cmdPeriod or window.onClose to evaluate that