//

(
var synths, globalBuffers, myServer;
var evFuncs, events, funcs;
var responders;
var window, mainLayout, guiElements; // for GUI - if used
var firstOutputChannel, globalAmp, pathPrefix;


// ------ settings/configuration ------
firstOutputChannel = 0;
globalAmp = 0.dbamp; // use dbValue.dbamp
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
myServer.hardwareBufferSize_(512); //the lower the value, the smaller the latency, but higher CPU load and more possibility or audio dropout; 512 is safe, 128 is low latency, lower still possible  but be sure to test
myServer.numOutputBusChannels_(2); //set higher number when using soundcard with multiple inputs/outputs
myServer.numInputBusChannels_(2); //set higher number when using soundcard with multiple inputs/outputs


myServer.waitForBoot({ //continune inside .waitForBoot, to make sure the server is ready

	// ---------- synths ---------
	synths = CtkProtoNotes(
		SynthDef(\synthName, {arg out = 0;
			var sig;
			sig = SinOsc.ar;
			Out.ar(out, sig * globalAmp)
		})
	);

	myServer.sync; //make sure synths are loaded;

	// ---------- buffers ---------
	//buffers for use throughout the piece
	// globalBuffers[\firstOne] = CtkBuffer.playbuf(pathPrefix ++ "filename").load;

	myServer.sync; //make sure buffers are loaded;

	//---------- misc functions -------
	//miscellaneous helper functions, like cleanup, converting parameters, etc...

	funcs[\cleanup] = { //free buffers, maybe synths, responders; trigger with window.onClose_({}) or CmdPeriod.doOnce({})
		"Cleaning up...".postln;
		// globalBuffers.do({|thisBuffer|
		// 	thisBuffer.free;
		// });
		// responders.do({|thisResponders|
		// 	thisResponder.free;
		// });
	};

	//---------- responders - if used:MIDI, OSC  -------
	//responders[\respName] = OSCdef(\respName, {}, '/path');

	// -----------------------------------------------------------------
	// ----------- now the main composing/creative work goes below ---------
	// -----------------------------------------------------------------

	//---------- event generating functions -------
	evFuncs[\name1] = {arg param1, param2;
		//Note, Task or ProcModR are being set up here
	};

	// -----------------------------------------------------------------
	// ----------- second part of main composing/creative work section ---------
	// -----------------------------------------------------------------

	//---------- event instances -------------

	//if using custom triggering/controllers, add instances of events to a dictionary
	// events[\event1] = evFuncs[\name1].value(1, 2);

	// if using a ProcModR, use procEvents for storing event instances
	// events = ProcEvents.new(
	// 	[
	// 		[//event 0
	// 			evFuncs[\name1].value(1, 2);
	// 			nil //nothing to release
	// 		], [//event 1
	// 			nil,
	// 			\name1, //release name1
	// 		]
	// 	], //all events array
	// 	0.dbamp, //global amp
	// 	nil, //initial procMod, starts with the first event
	// 	ProcMod.new.function_({funcs[\cleanup].value}),
	// 	//killmod, runs after closing ProcEvents Gui - needs to be a procmod or ProcModR
	// 	server: myServer
	// );

	//events.pracGUI; //for some reason recording works only with practice gui

	//if you use a GUI:
	// window = Window.new.front;
	// window.onClose_({funcs[\cleanup].value});

})
);
