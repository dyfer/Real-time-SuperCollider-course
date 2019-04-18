//another instance of templace, including master synth with ambisonics decoder and limiter

(
var synths, globalBuffers, myServer;
var evFuncs, events, funcs;
var responders;
var window, mainLayout, guiElements; // for GUI - if used
var mainGroup, masterGroup, mainBus;
var firstOutputChannel, mainVolume, pathPrefix;
var decoderType, decoderMatrix;


// ------ settings/configuration ------
firstOutputChannel = 0;
mainVolume = 0.dbamp; // use dbValue.dbamp
decoderType = \uhj; //possible \uhj - stereo, \hex - 6-channel, \bf - b-format directly to external decoder, \hrtf - for headphone listning
//possibly others, like hardwareBufferSize, numberOfOutputs etc; then use them below


// ------ initialization ----
pathPrefix = "".resolveRelative; //get path prefix here, since resolveRelative doesn't work inside Tasks...
//init dictinaries
evFuncs = IdentityDictionary.new;
events = IdentityDictionary.new;
funcs = IdentityDictionary.new;
globalBuffers = IdentityDictionary.new;
responders = IdentityDictionary.new;
//set server options
myServer = Server.default;
myServer.options.hardwareBufferSize_(512); //the lower the value, the smaller the latency, but higher CPU load and more possibility or audio dropout; 512 is safe, 128 is low latency, lower still possible  but be sure to test
myServer.options.numOutputBusChannels_(6); //set higher number when using soundcard with multiple inputs/outputs
myServer.options.numInputBusChannels_(2); //set higher number when using soundcard with multiple inputs/outputs


myServer.waitForBoot({ //continune inside .waitForBoot, to make sure the server is ready

	//------ prepare internal buffers for hrtf decoder - before synths ----
	if(decoderType == \hrtf, {
		decoderMatrix = FoaDecoderKernel.newSpherical;
		myServer.sync;
	});

	// ---------- synths ---------
	synths = CtkProtoNotes(
		SynthDef(\synthName, {arg out = 0, azimuth = 0, elevation = 0;
			var sig, outSig;
			sig = SinOsc.ar;
			outSig = FoaPanB.ar(	sig, azimuth, elevation);
			Out.ar(out, outSig); //no mainVolume here!
		}),
		SynthDef(\decoder, {arg in = 0, out = 0, level = 0.97, lookAhead = 0.01, revAmt = 0.11, roomsize = 80, revtime = 2, damping = 0.41, inputbw = 0.2, spread = 20, drylevel = 0, earlylevel = 0.3, taillevel = 0.35, hpfFreq = 30;
			var sndIn, sndOut;
			sndIn = In.ar(in, 4) * mainVolume; //4 channels; adjust volume before limiting
			//decode
			decoderType.switch(
				\uhj, {sndOut = B2UHJ.ar(sndIn[0], sndIn[1], sndIn[2])},
				\bf, {sndOut = sndIn},
				\hex, {sndOut = FoaDecode.ar(sndIn, FoaDecoderMatrix.newPanto(6, k: 'energy')).at([0, 5, 4, 3, 2, 1])},
				\hrtf, {sndOut = FoaDecode.ar(sndIn, decoderMatrix)}
			);
			sndOut = HPF.ar(sndOut, hpfFreq); //use this if you want a hi pass filter
			sndOut = Limiter.ar(sndOut, level, lookAhead); //soft limiter, sounds better, but has a delay of 2xlookAhead
			// sndOut = sndOut.clip(-1, 1); //hard limiter, sound worse, but is a basic protection when working on headphones; no delay so better for realtime processing
			Out.ar(out, sndOut);
		})
	);

	myServer.sync; //make sure synths are loaded;

	// ---------- main groups and buses ---------
	mainGroup = CtkGroup.play(server: myServer);
	myServer.sync;
	masterGroup = CtkGroup.play(server:myServer, addAction: \tail);
	mainBus = CtkAudio.new(4, server: myServer); //4 channels for b format!

	myServer.sync;

	// ---------- buffers ---------
	//buffers for use throughout the piece
	// globalBuffers[\firstOne] = CtkBuffer.playbuf(pathPrefix ++ "filename").load;

	myServer.sync; //make sure buffers are loaded;

	//---------- misc functions -------
	//miscellaneous helper functions, like cleanup, converting parameters, etc...

	funcs[\cleanup] = { //free buffers, maybe synths, responders; trigger with window.onClose_({}) or CmdPeriod.doOnce({})
		"Cleaning up...".postln;
		[mainGroup, masterGroup, mainBus].do({arg thisElement; //free various elements
			thisElement.free;
		});
		// globalBuffers.do({arg thisBuffer;
		// 	thisBuffer.free;
		// });
		// responders.do({arg thisResponders;
		// 	thisResponder.free;
		// });
	};

	//---------- responders - if used:MIDI, OSC  -------
	//responders[\respName] = OSCdef(\respName, {}, '/path');

	// -----------------------------------------------------------------
	// ----------- now the main composing/creative work goes below ---------
	// -----------------------------------------------------------------

	//---------- event generating functions -------
	evFuncs[\master] = {arg id = \master;
		var proc, fxBus, delayBuffer;
		proc = ProcModR.new(
			Env([0, 1, 0], [0, 2], \sin, 1), //note att and rel here
			1, //amp here
			6, //number of channels; depending on the devoder we'll use up to 6
			firstOutputChannel,
			id, //id - from args
			target: masterGroup, //group as a target, pre-set to the masterGroup
			server: s
		);
		proc.function_({arg group, routebus, server;
			Task({
				synths[\decoder].note(server: server, target: group, addAction: \tail)
				.in_(mainBus)
				.out_(routebus)
				.level_(0.97) //limiter leve
				.lookAhead_(0.01) // (half of) lookahead time for the limiter
				.hpfFreq_(30) //frequency for high-pass filter
				.play;
			});
		});
		proc; //make sure the function returns this proc
	};

	evFuncs[\name1] = {arg param1, param2;
		//Note, Task or ProcModR are being set up here
	};

	// -----------------------------------------------------------------
	// ----------- second part of main composing/creative work section ---------
	// -----------------------------------------------------------------

	//---------- event instances -------------

	//if using custom triggering/controllers, add instances of events to a dictionary
	// events[\event1] = evFuncs[\name1].value(1, 2);
	// events[\master] = evFuncs[\master] .value;

	// if using a ProcModR, use procEvents for storing event instances
	// events = ProcEvents.new(
	// 	[
	// 		[//event 0 - master processor
	//	            evFuncs[\master] .value,
	// 			nil
	// 		], [//event 1
	// 			evFuncs[\name1].value(1, 2),
	// 			nil,
	// 		], [//event 2
	// 			nil,
	// 			\name1, //release name1
	// 		]
	// 	], //all events array
	// 	0.dbamp, //global amp
	// 	nil, //initial procMod, starts with the first event
	// 	ProcMod.new.function_({funcs[\cleanup].value}), //run clenaup when you close proc window
	// 	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	// 	server: myServer
	// );

	//events.pracGUI; //for some reason recording works only with practice gui

	//if you use a GUI:
	// window = Window.new.front;
	// window.onClose_({funcs[\cleanup].value});

})
);
