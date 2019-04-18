//DX463
//Fall 2015
//class 04


/*
- Recording – HDR (note: multichannel recording is BROKEN in 3.6.6; use 3.6.5 or 3.7)
- slider/knob for tempo ?
- more
  - more Gui: knobs etc
  - controlSpec
  - ezgui

//first: note this syntax with arrays

#a, b = [1, 3];
a;
b;

#a, b = [[1, 3], [100, 300]];
a;
b;

//and flopping

[[1, 3], [100, 300]].flop

#a, b = [[1, 3], [100, 300]].flop;
a;
b;

executable

*/

//--------------------------------------------------
// note this syntax with arrays
//--------------------------------------------------

#a, b = [1, 3];
a;
b;

#a, b = [[1, 3, 5, 7], [100, 300, 560, 900]];
a;
b;

//and flopping

c = [[1, 3, 5, 7], [100, 300, 560, 900]].flop
c[2]

a = [0.2, 0.3, 2, 3.1];
b = [440, 560, 340, 500];
c = [0.6, 0.8, 0.5, 0.9];

d = [a, b, c].flop

d.do({arg parameters, inc;
	parameters.postln;
});

[ [ 1, 100 ], [ 3, 300 ], [ 5, 560 ], [ 7, 900 ] ]

#a, b = [[1, 3], [100, 300]].flop;
a;
b;



s.makeGui


//--------------------------------------------------
// HDR - a hard disk recorder
//--------------------------------------------------

//written by Josh
//part of JoshUGen package (found in SC3plugins)
//no help file, but it's fairly simple

(
~hdr = HDR.new(
	Server.default, //server
	[0, 1, s.options.numOutputBusChannels + 0, s.options.numOutputBusChannels + 1], //an array of all the channels to record
	sessionPath: "".resolveRelative, //current folder
	filename: "rec",
	headerFormat: "wav",
	sampleFormat: "float", //also int16, int24
)
)
~hdr.record
s.queryAllNodes
~hdr.stop

"".resolveRelative.openOS



//--------------------------------------------------
// Spec and ControlSpec
//--------------------------------------------------

// for mapping values
"ControlSpec".openHelpFile; //proper controlspec file
"Spec".openHelpFile; //see what shortcuts are available for creating ControlSpecs

//from the help file
g = ControlSpec(20, 20000, \exp, 0, 220, "Hz");
g.map(0.5); // convert from [0..1] to [0.01..2000]
g.unmap(1000); // convert from [0.01..2000] to [0..1]

// fore and back translation should be close to identical:
g.unmap(g.map(0.5));


//--------------------------------------------------
// EZGUI - EZSlider
//--------------------------------------------------

//now let's see EZSLider
(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;

relativeSearchPath = "../02/audio/*.wav"; //configuration

s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
		thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayer, {|buffer = 0, amp = 1|
		Out.ar(0, PlayBuf.ar(2, buffer) * amp);
	});

	//create a layout which will space our buttons
	vLayout = VLayout.new;

	//we also need a window
	window = Window.new("simple player");

	allButtons = allBuffers.collect({|thisBuffer, inc|
		var note, filename, thisButton, thisSlider;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		//create a button and add it to a layout
		vLayout.add(
			thisButton = Button(window)
			.states_([[filename], [filename ++ " playing"]])
			.action_({|buttonObject|
				buttonObject.value.postln;
				if(buttonObject.value.asBoolean, {
					//note obtaining amp from the slider
					note = synth.note.buffer_(thisBuffer).amp_(thisSlider.value.dbamp).play;
				}, {
					note.free;
				});
			});
		);
		vLayout.add(
			//also let's add volume control - slider
			thisSlider = EZSlider(window, label: "amp", controlSpec: ControlSpec(0.ampdb, 2.ampdb, \db, units: " dB"), initVal: 0, layout: \horz, unitWidth: 30)
			.action_({|slider|
				if(note.notNil, {
					note.amp_(slider.value.dbamp); //note dbamp here, since we're using decibel scale above (ControlSpec)
				});
			});
			thisSlider.view; //we're passing EZSlider's "view" to the layout, it won't work otherwise; this is fine, but doesn't always work as expected, see next example
		); //add to layout parenthesis
		thisButton; //we need this to add button to our allButtons variable!
	});

	//add layout to the window
	window.layout_(vLayout);

	//bring the window to front
	window.front;

	//free buffers on close
	window.onClose_({
		"stop all notes - through buttons".postln; //new - stopping all notes
		allButtons.do(_.valueAction_(0));
		"freeing buffers".postln;
		allBuffers.do(_.free);
	});

	window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
		var thisIndex, thisButton;
		[char, modifiers, unicode, keycode, key].postln;
		// char.class.postln;
		thisIndex = key - 49;
		"thisIndex: ".post; thisIndex.postln;
		// thisIndex = thisIndex.clip(0, allButtons.size - 1);
		// thisIndex = thisIndex % allButtons.size;
		if((thisIndex >= 0) && (thisIndex < allButtons.size), {
			thisButton = allButtons[thisIndex];
			// "thisButton.value.asBoolean: "a.post; thisButton.value.asBoolean.postln;
			if(thisButton.value.asBoolean, {
				thisButton.valueAction = 0;
				}, {
					thisButton.valueAction = 1;
			});
		});
	});
});
)

//---------------
// more ezGUIs - now with explicit layout-ing
//--------------
//add pan/balance

(
var window, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary, vLayout;

relativeSearchPath = "../02/audio/*.wav"; //configuration

s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
		thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayerWithPan, {|buffer = 0, amp = 1, pan = 0|
		var sig;
		sig = PlayBuf.ar(2, buffer);
		Out.ar(0, Balance2.ar(sig[0], sig[1], pan, amp));
	});

	//create a layout which will space our buttons
	vLayout = VLayout.new;

	//we also need a window
	window = Window.new("simple player", 600@400/*syntactical shorcut to create a Point*/);

	allButtons = allBuffers.collect({|thisBuffer, inc|
		var note, filename, thisButton, thisSlider, thisKnob;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		//before adding more to the layout, let's create the button and ezgui objects first

		thisButton = Button(window)
		.states_([[filename], [filename ++ " playing"]])
		.action_({|buttonObject|
			buttonObject.value.postln;
			if(buttonObject.value.asBoolean, {
				note = synth.note.buffer_(thisBuffer).play;
			}, {
				note.free;
			});
		});

		thisSlider = EZSlider(window, label: "amp", controlSpec: ControlSpec(0.ampdb, 2.ampdb, \db, units: " dB"), initVal: 0, layout: \horz, unitWidth: 30)
		.action_({|slider|
			if(note.notNil, {
				note.amp_(slider.value.dbamp); //note dbamp here, since we're using decibel scale above (ControlSpec)
			});
		});

		thisKnob = EZKnob(window, controlSpec: \pan, label: "pan", layout: \vert)
		.action_({|knob|
			if(note.notNil, {
				note.pan_(knob.value);
			});
		});

		//now this will get somewhat messy... since EZGuis don't play nice with the layouts, we'll put the views of indivitual elements of each ezgui in a layout
		//it SHOULD be like this....
/*		vLayout.add( //add to the general layout
			HLayout(
				VLayout(
					thisButton, //button here
					thisSlider.view
				), //use HLayout to set 4 elements of the ezslider
				thisKnob.view
			),
		); //add to layout parenthesis*/

		//but needs to be like this for the time being
		vLayout.add( //add to the general layout
			HLayout(
				VLayout(
					thisButton, //button here
					HLayout(
						thisSlider.labelView,
						thisSlider.sliderView,
						thisSlider.numberView.maxWidth_(40), //number box seems the only thing that doesn't scale reasonably by default, so we limit its width here
						thisSlider.unitView //since we've set the unitWidth > 0 above, in slider declaration
					) //use HLayout to set 4 elements of the ezslider
				),
				VLayout(
					thisKnob.labelView,
					thisKnob.knobView,
					thisKnob.numberView.maxWidth_(40) //as above
					//no unitview here since we are not "enabling" it in the declaration
				) //as above
			);
		); //add to layout parenthesis

		thisButton; //we need this to add button to our allButtons variable!
	});

	//add layout to the window
	window.layout_(vLayout);

	//bring the window to front
	window.front;

	//free buffers on close
	window.onClose_({
		"stop all notes - through buttons".postln;
		allButtons.do(_.valueAction_(0));
		"freeing buffers".postln;
		allBuffers.do(_.free);
	});

	//see "Char".openHelpFile;
	//also "Dictionary".openHelpFile;

	window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
		var thisIndex, thisButton;
		[char, modifiers, unicode, keycode, key].postln;
		// char.class.postln;
		thisIndex = key - 49;
		"thisIndex: ".post; thisIndex.postln;
		// thisIndex = thisIndex.clip(0, allButtons.size - 1);
		// thisIndex = thisIndex % allButtons.size;
		if((thisIndex >= 0) && (thisIndex < allButtons.size), {
			thisButton = allButtons[thisIndex];
			// "thisButton.value.asBoolean: "a.post; thisButton.value.asBoolean.postln;
			if(thisButton.value.asBoolean, {
				thisButton.valueAction = 0;
				}, {
					thisButton.valueAction = 1;
			});
		});
	});
});
)
