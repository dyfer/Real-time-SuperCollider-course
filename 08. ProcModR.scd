//triggering - ProcModR & ProcEvents
"ProcModR".openHelpFile; //help not available currently

//0 groups and buses
//1 basic proc
//2 functinoal


//procevents
//perfgui, pracgui

//releaseFunc, onReleaseFunc
//recording


//procsink

//Process
//Modular
//Record


//------------------------------------------
// CtkGroup - simple example (no sound)
//------------------------------------------
s.reboot;
s.boot;
s.queryAllNodes; //post to window
s.plotTree; //GUI!

//first - no explicit group:
(
var synths, procs;
var firstOutputChannel;
firstOutputChannel = 0;

s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus, freq, amp, dur, gate = 1;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env([0, 1, 0], [1, 2], \lin, 1), gate: gate, doneAction: 2) * amp,
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);
	~note = synths[\singrain].note.freq_(rrand(440, 1760)).amp_(-12.dbamp).outbus_(firstOutputChannel).play;
});
)
~note.release;

//same, multiple notes
(
var synths, procs;
var firstOutputChannel;
firstOutputChannel = 0;

s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus, freq, amp, dur, gate = 1;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env([0, 1, 0], [1, 2], \lin, 1), gate: gate, doneAction: 2) * amp,
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);
	~note = 10.collect({
		synths[\singrain].note.freq_(rrand(440, 1760)).amp_(-12.dbamp).outbus_(firstOutputChannel).play;
	});
});
)
~note;
~note.do({|thisNote| thisNote.release});


//now - put them in a group
(
var synths, group;
var firstOutputChannel;
firstOutputChannel = 0;

s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus, freq, amp, dur, gate = 1;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env([0, 1, 0], [1, 2], \lin, 1), gate: gate, doneAction: 2) * amp,
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);

	group = CtkGroup.play;
	~group = group; //assign global variable to it

	10.do({ //no need to collect!
		synths[\singrain].note(target: group).freq_(rrand(440, 1760)).amp_(-12.dbamp).outbus_(firstOutputChannel).play; //note we're specifying target - a group
	});
});
)
~group.release; //releases all notes in a group
~group.free; //free when you're done with it


//and multiple groups
(
var synths, group, group2;
var firstOutputChannel;
firstOutputChannel = 0;

s.waitForBoot({
	synths = CtkProtoNotes(
		SynthDef(\singrain, {arg outbus, freq, amp, dur, gate = 1;
			Out.ar(outbus,
				Pan2.ar(
					SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env([0, 1, 0], [1, 2], \lin, 1), gate: gate, doneAction: 2) * amp,
					Rand.new(-1.0, 1.0)
				)
			)
		})
	);

	group = CtkGroup.play;
	group2 = CtkGroup.play;
	~group = group; //assign global variable to it
	~group2 = group2; //assign global variable to it

	10.do({ //no need to collect!
		synths[\singrain].note(target: group).freq_(rrand(640, 1760)).amp_(-19.dbamp).outbus_(firstOutputChannel).play; //note we're specifying target - a group
	});
	10.do({ //no need to collect!
		synths[\singrain].note(target: group2).freq_(rrand(140, 260)).amp_(-16.dbamp).outbus_(firstOutputChannel).play; //note we're specifying target - a group
	});

});
)
~group.release; //releases all notes in a group
~group2.release; //releases all notes in a group
~group.free; ~group2.free; //free when you're done with it


//and now: -> ProcModR

//------------------------------------------
// ProcModR - simple example (no sound)
//------------------------------------------
s.boot;
(
// create a new ProcModR, and assign a function to it
~pm1 = ProcModR.new(
	Env([0, 1, 0], [0.1, 0.1], \sin, 1), //global envelope - not attack/decay time
	0.dbamp, //global amplitude
	2, //number of channels
	0, //output bus
	\slowSines, //id (any name - a Symbol)... will become handy
	server: s);
~pm1.function_({arg group, routebus, server;
	//inside the function you want to have a Task
	Task({
		"one potato".postln;
		1.wait;
		"two potatoes".postln;
		1.wait;
		"three potatoes".postln;
		0.75.wait;
		"four".postln;
	});
});
)

~pm1.play;
~pm1.release;
~pm1.isRunning

if(~pm1.isRunning, {~pm1.release;}); ~pm1.play;



//------------------------------------------
// ProcModR - basic
//------------------------------------------

(
var synths, procs;
var firstOutputChannel;
firstOutputChannel = 0;

synths = CtkProtoNotes(
	SynthDef(\singrain, {arg outbus, freq, amp, dur;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.sine(dur, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	})
);

// create a new ProcModR, and assign a function to it
~pm1 = ProcModR.new(
	Env([0, 1, 0], [1, 1], \sin, 1), //global envelope
	0.dbamp, //global amplitude
	2, //number of channels
	firstOutputChannel, //output bus
	\slowSines, //id (any name - a Symbol)... will become handy
	server: s);
~pm1.function_({arg group, routebus, server; //routebus is an output bus for this ProcModR; use it as output in your synths
	//inside the function you want to have a Task
	Task({
		1.do({
			// start a new synth... run it inside this ProcModR's group
			synths[\singrain].note(server: server, target: group).freq_(rrand(440, 1760)).amp_(-12.dbamp).dur_(500).outbus_(routebus).play; //note we're specifying target (procmod's group) and server
			0.5.wait;
		})
	});
});
)

~pm1.play;
~pm1.release;


//------------------------------------------
// ProcModR - functional creation
//------------------------------------------
(
var synths, procs;
var firstOutputChannel;
firstOutputChannel = 0;

synths = CtkProtoNotes(
	SynthDef(\singrain, {arg outbus, freq, amp, dur;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.sine(dur, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	})
);

// create a Function with some arguments, create proc inside, use arguments inside, return procmod
~pmFunc1 = {arg minFreq = 440, maxFreq = 1760; //parameters we'd like to have control over
	var proc;
	proc = ProcModR.new(
		Env([0, 1, 0], [1, 1], \sin, 1), //global envelope
		0.dbamp, //global amplitude
		2, //number of channels
		firstOutputChannel, //output bus
		\slowSines, //id (any name - a Symbol)... will become handy
		server: s);
	proc.function_({arg group, routebus, server;
		Task({
			inf.do({
				synths[\singrain].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-12.dbamp)
				.dur_(5)
				.outbus_(routebus)
				.play; //this is one line of code, BTW
				0.5.wait;
			})
		});
	});
	proc; //make sure the function returns this proc
};
)

~pm1 = ~pmFunc1.(); //same as ~pmFunc1.value()
~pm1.play;
~pm1.release;


~pm2 = ~pmFunc1.(100, 302); //same as ~pmFunc1.value(100, 302)
~pm2.play;
~pm2.release;



//------------------------------------------
// ProcModR - functional creation - more args
//------------------------------------------
(
var synths, procs;
var firstOutputChannel;
firstOutputChannel = 0;

synths = CtkProtoNotes(
	SynthDef(\singrain, {arg outbus, freq, amp, dur;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.sine(dur, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	})
);

// we want to have control over more things, probably; you choose the order as far as the function goes
~pmFunc1 = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
	var proc;
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s);
	proc.function_({arg group, routebus, server;
		Task({
			inf.do({
				synths[\singrain].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(routebus)
				.play; //this is one line of code, BTW
				0.5.wait;
			})
		});
	});
	proc; //make sure the function returns this proc
};
)

~pm1 = ~pmFunc1.(\nameOne, -12.dbamp, 880, 1760, rel: 1);
~pm1.play;
~pm1.release;


~pm2 = ~pmFunc1.(\nameTwo, -3.dbamp, 100, 302, rel: 10);
~pm2.play;
~pm2.release;


//------------------------------------------
// ProcEvents - putting events (in order)
//------------------------------------------

"ProcEvents".openHelpFile
//also - bye bye, global vars!
(
var synths, pmFunc1, pEvents;
var firstOutputChannel;
firstOutputChannel = 0;

synths = CtkProtoNotes(
	SynthDef(\singrain, {arg outbus, freq, amp, dur;
		Out.ar(outbus,
			Pan2.ar(
				SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.sine(dur, amp), doneAction: 2),
				Rand.new(-1.0, 1.0)
			)
		)
	})
);

// we want to have control over more things, probably; you choose the order as far as the function goes
pmFunc1 = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
	var proc;
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s);
	proc.function_({arg group, routebus, server;
		Task({
			inf.do({
				synths[\singrain].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(routebus)
				.play; //this is one line of code, BTW
				0.5.wait;
			})
		});
	});
	proc; //make sure the function returns this proc
};

//ProcEvents
//*new(events, amp, initmod, killmod, id, server)

//events - an array of events (ProcModRs or a function) to play / release  in the following format: [[ProcModR, ProcModR.id to release]] or [[ProcModR, ProcModR2], [ProcModR.id to release, ProcModR.id to release]]

pEvents = ProcEvents.new(
	[
		[//event 0
			[pmFunc1.(\nameOne, -12.dbamp, 880, 1760, rel: 1), pmFunc1.(\nameOneAndAHalf, -12.dbamp, 1880, 2760, rel: 1)],
			nil //nothing to release
		], [//event 1
			pmFunc1.(\nameTwo, -3.dbamp, 100, 302, rel: 10),
			nil,
		], [//event 2
			nil, //nothing to start
			\nameOne //release this one
		], [//event 3
			nil,
			[\nameTwo, \nameOneAndAHalf]
		]
	], //all events array
	0.dbamp, //global amp
	nil, //initial procModR, starts with the first event
	ProcMod.new.function_({"I run after closing procevents window, use me to free buffers etc".postln}), 	//killmod, runs after closing ProcEvents Gui - needs to be a procmod, I'm creating one here with just one function
	server: s
);

// pEvents.perfGUI; //gui for advancing
pEvents.pracGUI; //gui for practice - either that or just perfGUI

)

//------------------------------------------
// ProcMod - releaseFunc, onReleaseFunc
//------------------------------------------
(
var synths, pmFunc1, pEvents;
var firstOutputChannel;
firstOutputChannel = 0;

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
	})
);

pmFunc1 = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
	var proc;
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s);
	proc.function_({arg group, routebus, server;
		Task({
			inf.do({
				synths[\singrain].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(routebus)
				.play; //this is one line of code, BTW
				0.5.wait;
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
		id.post; " is done. You can free resources needed for this procmodr (like Buses) here.".postln;
	});
	proc; //make sure the function returns this proc
};

//events - an array of events (ProcModRs or a function) to play / release  in the following format: [ProcModR, ProcModR.id to release]
pEvents = ProcEvents.new(
	[
		[//event 0
			pmFunc1.(\nameOne, -12.dbamp, 880, 1760, rel: 1),
			nil //nothing to release
		], [//event 1
			pmFunc1.(\nameTwo, -3.dbamp, 100, 302, rel: 10),
			nil,
		], [//event 2
			nil, //nothing to start
			\nameOne //release this one
		], [//event 3
			nil,
			\nameTwo
		]
	], //all events array
	0.dbamp, //global amp
	nil, //initial procModR, starts with the first event
	ProcModR.new(Env.perc, 1, 2).function_({"I run after closing procevents window, use me to free buffers etc".postln}),
	//killmod, runs after closing ProcEvents Gui - needs to be a procmod
	server: s
);

// pEvents.perfGUI; //gui for advancing
pEvents.pracGUI; //gui for practice

)

//------------------------------------------
// ProcMod - releaseFunc, onReleaseFunc - practical example with a bus and a buffer
//------------------------------------------
(
var synths, pmFunc1, pEvents;
var firstOutputChannel;
firstOutputChannel = 0;

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
				`[1, 0.8, 0.97, 0.9],
				In.ar(inbus, 2),
				bufnum: buffer
			)
		)
	})
);

pmFunc1 = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
	var proc, fxBus, delayBuffer; //declare whatever you need to free afterwards here (Buses, Buffers etc)
	proc = ProcModR.new(
		Env([0, 1, 0], [att, rel], \sin, 1), //note att and rel here
		amp, //amp here
		2,
		firstOutputChannel,
		id, //id - from args
		server: s
	);
	proc.function_({arg group, routebus, server;
		Task({
			fxBus = CtkAudio(2, server: s);
			delayBuffer = CtkBuffer(size: s.sampleRate * 2, numChannels: 2, server: server).load; //loading buffer here might not be the best since it takes time;
			server.sync; //wait for the server to load the buffer!
			synths[\tapdelay].note(server: server, target: group, addAction: \tail).outbus_(routebus).inbus_(fxBus).buffer_(delayBuffer).play; //start delay
			inf.do({
				synths[\percsin].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(fxBus)
				// .outbus_(routebus)
				.play; //this is one line of code, BTW
				1.5.wait;
			})
		});
	});
/*	proc.onReleaseFunc_({arg group, routebus, server;
		"I'm triggered when the release STARTS".postln;
		synths[\percsin].note(server: server, target: group)
		.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
		.amp_(-9.dbamp)
		.dur_(5)
		.outbus_(routebus)
		.play;
	});*/
	proc.releaseFunc_({
		id.post; " is done. You can free resources needed for this procmod (like Buses) here.".postln;
		delayBuffer.free;
		fxBus.free;
		// [delayBuffer, fxBus].do(_.free); // <-- free the bus and the buffer here!
	});
	proc; //make sure the function returns this proc
};

//events - an array of events (ProcMods or a function) to play / release  in the following format: [ProcMod, ProcMod.id to release]
pEvents = ProcEvents.new(
	[
		[//event 0
			pmFunc1.(\nameOne, -12.dbamp, 880, 1760, rel: 1),
			nil //nothing to release
		], [//event 1
			pmFunc1.(\nameTwo, -3.dbamp, 100, 302, rel: 10),
			nil,
		], [//event 2
			nil, //nothing to start
			\nameOne //release this one
		], [//event 3
			nil,
			\nameTwo
		]
	], //all events array
	0.dbamp, //global amp
	nil, //initial procMod, starts with the first event
	ProcMod.new.function_({"I run last, use me to free buffers etc".postln}),
	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	server: s
);

// pEvents.perfGUI; //gui for advancing
pEvents.pracGUI; //gui for practice

)

//------------------------------------------
// ProcModR - recording - NOT WORKING CURRENTLY?
//------------------------------------------
(
var synths, pmFunc1, pEvents;
var firstOutputChannel, recordProcsToDisk, recordPath;
firstOutputChannel = 0;
recordProcsToDisk = false; //so we can switch it on/off easily
recordPath = "".resolveRelative; //just the same path as our SC file
recordPath.postln;

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



pmFunc1 = {arg id = \slowSine, amp = 0.dbamp, minFreq = 440, maxFreq = 1760, att = 1, rel = 5;
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
			delayBuffer = CtkBuffer(size: s.sampleRate * 2, numChannels: 2, server: server).load(sync: true); //loading buffer here might not be the best since it takes time;
			server.sync; //wait for the buffor to load
			synths[\tapdelay].note(server: server, target: group, addAction: \tail).outbus_(routebus).inbus_(fxBus).buffer_(delayBuffer).play; //start delay
			inf.do({
				synths[\percsin].note(server: server, target: group)
				.freq_(rrand(minFreq, maxFreq)) //<<--- see args here
				.amp_(-9.dbamp)
				.dur_(5)
				.outbus_(fxBus)
				// .outbus_(routebus)
				.play; //this is one line of code, BTW
				"here".postln;
				1.5.wait;
			});
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

//events - an array of events (ProcMods or a function) to play / release  in the following format: [ProcMod, ProcMod.id to release]
pEvents = ProcEvents.new(
	[
		[//event 0
			pmFunc1.(\nameOne, -12.dbamp, 880, 1760, rel: 1),
			nil //nothing to release
		], [//event 1
			pmFunc1.(\nameTwo, -3.dbamp, 100, 302, rel: 10),
			nil,
		], [//event 2
			nil, //nothing to start
			\nameOne //release this one
		], [//event 3
			nil,
			\nameTwo
		]
	], //all events array
	0.dbamp, //global amp
	nil, //initial procMod, starts with the first event
	ProcMod.new.function_({"I run last, use me to free buffers etc".postln}),
	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	server: s
);

pEvents.perfGUI; //gui for advancing
// pEvents.pracGUI; //for some reason recording works only with practice gui

)










//------------------------------------------
// ProcEvents - more procs at the same time
//------------------------------------------

(
var synths, pmFuncs, pEvents;
var firstOutputChannel, recordProcsToDisk, recordPath;
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
			delayBuffer = CtkBuffer(size: s.sampleRate * 2, numChannels: 2, server: server).load; //loading buffer here might not be the best since it takes time;
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



pmFuncs[\fast] = {arg id = \fastPerf, amp = 0.dbamp, att = 1, rel = 5, numGrains = 100;
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
			numGrains.do({|i|
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
			pmFuncs[\slow].(\nameOne, -12.dbamp, 880, {~maxFreqGlobal}, rel: 1),
			nil //nothing to release
		], [//event 1
			[
				pmFuncs[\slow].(\nameTwo, -3.dbamp, 100, 302, rel: 10),
				pmFuncs[\fast].(\nameFast, -3.dbamp, numGrains: 200),
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
	ProcMod.new.function_({"I run last, use me to free buffers etc".postln}),
	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	server: s
);

// pEvents.perfGUI; //gui for advancing
pEvents.pracGUI; //for some reason recording works only with practice gui

)
~maxFreqGlobal = 3;
