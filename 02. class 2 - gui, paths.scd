// Class 2


//----------------------------------------------------------------
//file Paths
//----------------------------------------------------------------


//It's a good idea to have all the related files (SC code, audio files, other files if used) in one folder.
//Now how to tell SC they're right next to the SC code? Or in any other RELATIVE location?

"".resolveRelative; //whoa

//now some basic *nix path navigation
"../audio/".resolveRelative; //this is up one level... although you can't tell yet probably


//let's combine that with another useful String method: .pathMatch; use wildcards to return number of results
"*".resolveRelative.pathMatch; //all files in the directory; returns an array of paths

//print it nicely
"*".resolveRelative.pathMatch.do({arg thisPath, inc; thisPath.postln;}); //iterate over these paths and print them with carriage return (".postln")

//syntax shortcut
"*".resolveRelative.pathMatch.do(_.postln); //syntax shortcut for iterating over stuff and doing single thing

//now let's see if we can list the parent directory
"../*".resolveRelative.pathMatch; //yeah

//and print nicely
"../*".resolveRelative.pathMatch.do(_.postln)

//still not sure if that ../ actually gets us anywhere? let's try with an audio file

a = "../audio/1-01 Berio_ Sequenza 1 For Flute.wav".resolveRelative;
b = File.exists(a); //quite useful check!
//we could even be lazy and try to resolve the name for us...
c = "audio/*Flute*".resolveRelative.pathMatch;
c.class;//array!
//so to get the path
d = c[1];
d.class; //string
File.exists(d);
//but if we have more than one file containing key word, like
e = "audio/*.wav".resolveRelative.pathMatch;
e.class;
e.size; // paths
//then
f = e[0];//takes the first file path


//so... back to our soundfile
d.postln;//our file path
s.boot;
g = CtkBuffer.playbuf(d).load;


x = {PlayBuf.ar(2, g)}.play;
x.free;

//clean up
g.free

//now multiple buffers
//using previous example
"../../../../2014-2015/DX598*/*".resolveRelative.pathMatch;
(
~allBuffers = "../../../../2014-2015/DX598*/audio/01*/Kontakte/*.wav".resolveRelative.pathMatch.collect({|thisPath| //iterate over all the matching file paths and return all the results as an array (".collect")
	thisPath.postln; //so we can see what's happening
	CtkBuffer.playbuf(thisPath).load(sync: true);//last element of the function is always returned; load causes the buffer to be actually loaded on the server
});
)

~allBuffers //an array of CtkBuffers

//so for test we can do
x = {PlayBuf.ar(2, ~allBuffers[0])}.play;
x.free;

//or randomly
x = {PlayBuf.ar(2, ~allBuffers.choose)}.play;
x.free;

//last, but not least - free everythin
~allBuffers.do({|thisBuffer| thisBuffer.free})
//or
~allBuffers.do(_.free);


//----------------------------------------------------------------
//iteration
//----------------------------------------------------------------

(
10.do({|increment|
	increment.postln;
});
)

(
a = 10.collect({|increment|
	increment.postln;
});
)
a

(
a = 10.collect({|increment|
	increment.postln;
	[increment, "i'm just a string"];
});
)

(
a = 10.collect({|increment|
	increment.postln;
	increment + 23;
});
)

a.at(0);
a[0];
a[3..6];
a[0, 2, 5];
a.at(0, 2, 5);
a.at()
a

a.indexOf(32)

(
b = a.collect({|thisItem, increment|
	thisItem * increment;
})
)
b;

b = b.add("something completely else");
b

Collection.openHelpFile


//----------------------------------------------------------------
//note on organizing projects
//----------------------------------------------------------------

//SuperCollider doesn't provide version control system, nor straightforward ability to use multiple files for one project
//I believe it's a good idea to increment version number in the file name (e.g. project01.scd, project02.scd) to be able to revert to previous version if needed
//of course it's a good idea to move on to the next version when you have code in a working state, not broken...
//alternatively one can use an external version control system, like git (I almost never bother, but it's seems like a good idea)



//----------------------------------------------------------------
//GUI
//----------------------------------------------------------------

(
w = Window.new("GUI Introduction", Rect(200,200,255,100));
b = Button.new(w,Rect(10,0,80,30)).states_([["Hide"],["Show"],["third state"]]);
s = Slider.new(w,Rect(95,0,150,30));
c = CompositeView.new(w,Rect(20,35,100,60));
StaticText.new(c,Rect(0,0,80,30)).string_("Hello");
StaticText.new(c,Rect(20,30,80,30)).string_("World!");
b.action = { c.visible = b.value.asBoolean.not };
s.action = { c.bounds = Rect( s.value * 150 + 20, 35, 100, 100 ) };
w.front;
)

//Layout! keeps things nice and neat
(
w = Window.new("GUI Introduction").layout_(
    VLayout(
        HLayout( Button(), TextField(), Button() ),
        TextView()
    )
).front;
)

//simple player
(
var window, layout, allBuffers, relativeSearchPath, fileNames, synth;

relativeSearchPath = "../../../../2014-2015/DX598*/audio/01*/Kontakte/*.wav"; //configuration

s = Server.default;
s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
		thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayer, {|buffer = 0|
		Out.ar(0, PlayBuf.ar(2, buffer));
	});

	//prepare window and layout
	window = Window.new("simple player").front; //put window to front right away
	layout = VLayout.new;
	window.layout_(layout);

	allBuffers.do({|thisBuffer, inc|
		var note, filename;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		layout.add(//add the button to the layout
			Button(window)
			.states_([[filename], [filename ++ " playing"]])
			.action_({|buttonObject|
				buttonObject.value.postln;
				if(buttonObject.value.asBoolean, {
					note = synth.note.buffer_(thisBuffer).play;
				}, {
					note.free;
				});
			});
		);
	});


	window.onClose_({
		"freeing buffers".postln;
		allBuffers.do(_.free);
	})
});
)

//same but with keyboard control - preset mappings with keys
(
var window, layout, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary;

relativeSearchPath = "../../../../2014-2015/DX598*/audio/01*/Kontakte/*.wav"; //configuration

s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
	thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayer, {|buffer = 0|
		Out.ar(0, PlayBuf.ar(2, buffer));
	});

	//prepare window and layout
	window = Window.new("simple player").front; //put window to front right away
	layout = VLayout.new;
	window.layout_(layout);

	allButtons = allBuffers.collect({|thisBuffer, inc|
		var note, filename, button;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		layout.add(//add the button to the layout
			button = Button(window)
			.states_([[filename], [filename ++ " playing"]])
			.action_({|buttonObject|
				buttonObject.value.postln;
				if(buttonObject.value.asBoolean, {
					note = synth.note.buffer_(thisBuffer).play;
				}, {
					note.free;
				});
			});
		);
		button;//IMPORTANT - this will go to allButtons
	});


	window.onClose_({
		"freeing buffers".postln;
		allBuffers.do(_.free);
	});
	mappingDictionary = Dictionary.new.putPairs([
		$1, 0,
		$2, 1,
		$3, 2,
		$a, 3
	]);
	//see "Char".openHelpFile;
	//also "Dictionary".openHelpFile;

	window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
		var thisIndex, thisButton;
		[char, modifiers, unicode, keycode, key].postln;
		// char.class.postln;
		thisIndex = mappingDictionary[char];
		"thisIndex: ".post; thisIndex.postln;
		thisButton = allButtons[thisIndex];
		"thisButton.value.asBoolean: ".post; thisButton.value.booleanValue.postln;
		if(thisButton.value.booleanValue, {
			thisButton.valueAction = 0;
		}, {
			thisButton.valueAction = 1;
		});
	});
});
)


//alternative way of mapping - offset
(
var window, layout, allBuffers, relativeSearchPath, fileNames, synth, allButtons, mappingDictionary;

relativeSearchPath = "../../../../2014-2015/DX598*/audio/01*/Kontakte/*.wav"; //configuration

s.waitForBoot({

	allBuffers = relativeSearchPath.resolveRelative.pathMatch.collect({|thisPath|
	thisPath.postln; //so we can see what's happening
		CtkBuffer.playbuf(thisPath).load(sync: true);
	});

	//prepare synth
	synth = CtkSynthDef(\stereoPlayer, {|buffer = 0|
		Out.ar(0, PlayBuf.ar(2, buffer));
	});

	//prepare window and layout
	window = Window.new("simple player").front; //put window to front right away
	layout = VLayout.new;
	window.layout_(layout);

	allButtons = allBuffers.collect({|thisBuffer, inc|
		var note, filename, button;
		filename = thisBuffer.path.basename;
		filename.postln; //just the filename, without full path, use for display
		layout.add(//add the button to the layout
			button = Button(window)
			.states_([[filename], [filename ++ " playing"]])
			.action_({|buttonObject|
				buttonObject.value.postln;
				if(buttonObject.value.asBoolean, {
					note = synth.note.buffer_(thisBuffer).play;
				}, {
					note.free;
				});
			});
		);
		button;//IMPORTANT - this will go to allButtons
	});


	window.onClose_({
		"freeing buffers".postln;
		allBuffers.do(_.free);
	});
	//see "Char".openHelpFile;
	//also "Dictionary".openHelpFile;

	window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
		var thisIndex, thisButton;
		[char, modifiers, unicode, keycode, key].postln;
		// char.class.postln;
		// thisIndex = mappingDictionary[char];
		thisIndex = unicode - 49; //49 is unicode for number 0
		"thisIndex: ".post; thisIndex.postln;
		thisButton = allButtons[thisIndex];
		"thisButton.value.asBoolean: ".post; thisButton.value.booleanValue.postln;
		if(thisButton.value.booleanValue, {
			thisButton.valueAction = 0;
		}, {
			thisButton.valueAction = 1;
		});
	});
});
)

Server.killAll //if server hangs, e.g. after disconnecting audio interface
//see more at
"Introduction to GUI".openHelpFile;

//

//clocking
(
w=Window.new.front;
Routine{
    20.do{
    w.bounds=Rect(200.rand, 200+200.rand, 300,300);
    0.1.wait;
    };
    w.close;
}.play(AppClock)
)
//vs
(
w=Window.new.front;
Routine{
    20.do{
		    {w.bounds=Rect(200.rand, 200+200.rand, 300,300) }.defer; // you must defer this
    0.1.wait;
    };
    {w.close}.defer; // you must defer this
}.play(SystemClock);
)
//this will be important when you want to control GUI from messages from the synth for example!