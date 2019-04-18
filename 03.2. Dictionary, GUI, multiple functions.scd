//DX463
//Fall 2015
//class 03.2

/*
03.2
- function for creating tasks
- task -> button
- slider for task's/synth's parameters
- multiple tasks, buttons

- lab:
  - extend previous assignment to create:
    - multiple tasks
    - control them on/off with bottons
    - control at least one parameter inside each of them with a slider
- hw
  - use the framework from the lab
  - create more tasks (think modular)
  - control more parameters with sliders
*/


s.boot;
//--------------------------------------------------
// creating Tasks from Functions
//--------------------------------------------------

//so far we don't have an easy way to pass parameters when creating a Task
//what if we use a function to create a Task?

//recall last realtime example from the first class
(
var task, synth, options, times, freqs, amps;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

times = [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ]; //relative times
freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

task = Task({
	times.size.do({arg inc;
		"current time diff: ".post; times[inc].postln;
		times[inc].wait; //wait for a specified time
		synth.note(0, 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]).play; //0 as startTime, and .play it
	});
});
task.play;//play the dask
)

//what if we wanted to create numerous tasks that do smiliar thing? how about:
(
var taskFunction, tasks, synth;

tasks = IdentityDictionary.new;//create a dictionary for storing individual tasks

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

//we don't need these anymore
// times = [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ]; //relative times
// freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
// amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

taskFunction = {arg argTimes, argFreqs, argAmps;
	Task({
		argTimes.size.do({arg inc;
			"current time diff: ".post; argTimes[inc].postln;
			argTimes[inc].wait; //wait for a specified time
			synth.note(0, 2.0).freq_(argFreqs[inc]).envDur_(2).amp_(argAmps[inc]).play; //0 as startTime, and .play it
		});
	});
};//note change of variable/argument names, just for clarity times -> argTimes, freqs -> argFreqs etc

tasks[\firstOne] = taskFunction.value(
	argTimes: [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ],
	argFreqs: [420, 440, 440, 548, 332, 656, 424, 564, 816, 412],
	argAmps: [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]
);
//argument names are included for clarity; you can also do
//tasks[\firstOne] = taskFunction.value([ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ], [420, 440, 440, 548, 332, 656, 424, 564, 816, 412], [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]);
tasks[\firstOne].play;//play the dask
)

//now let's create more tasks using just one function

(
var taskFunction, tasks, synth;

tasks = IdentityDictionary.new;//create a dictionary for storing individual tasks

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

taskFunction = {arg argTimes, argFreqs, argAmps;
	Task({
		argTimes.size.do({arg inc;
			"current time diff: ".post; argTimes[inc].postln;
			argTimes[inc].wait; //wait for a specified time
			synth.note(0, 2.0).freq_(argFreqs[inc]).envDur_(2).amp_(argAmps[inc]).play; //0 as startTime, and .play it
		});
	});
};//note change of variable/argument names, just for clarity times -> argTimes, freqs -> argFreqs etc

tasks[\first] = taskFunction.value(
	argTimes: [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ],
	argFreqs: [420, 440, 440, 548, 332, 656, 424, 564, 816, 412],
	argAmps: [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]
);

tasks[\random] = taskFunction.value(
	argTimes: 10.collect({rrand(0.2, 0.8)}),
	argFreqs: 10.collect({rrand(400, 1200.2)}),
	argAmps: 10.collect({rrand(0.3, 0.3)})
);

tasks[\randomDense] = taskFunction.value(
	argTimes: 200.collect({rrand(0.05, 0.2)}),
	argFreqs: 200.collect({rrand(400, 1200.2)}),
	argAmps: 200.collect({rrand(0.08, 0.1)})
);

//use a routine to play tasks one after another
Routine.run({
	tasks[\first].play;
	6.wait; //wait before the second one
	tasks[\random].play;
	8.wait;
	tasks[\randomDense].play;
});
)


//--------------------------------------------------
// using GUI to control tasks
//--------------------------------------------------

(
var taskFunction, tasks, synth;
var window, layout, allButtons;

tasks = IdentityDictionary.new;//create a dictionary for storing individual tasks

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 2);
	Out.ar(0, osc * env)
});

taskFunction = {arg argTimes, argFreqs, argAmps;
	Task({
		argTimes.size.do({arg inc;
			"current time diff: ".post; argTimes[inc].postln;
			argTimes[inc].wait; //wait for a specified time
			synth.note.freq_(argFreqs[inc]).envDur_(2).amp_(argAmps[inc]).play; //0 as startTime, and .play it
		});
	});
};//note change of variable/argument names, just for clarity times -> argTimes, freqs -> argFreqs etc

tasks[\first] = taskFunction.value(
	argTimes: [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ],
	argFreqs: [420, 440, 440, 548, 332, 656, 424, 564, 816, 412],
	argAmps: [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2]
);

tasks[\random] = taskFunction.value(
	argTimes: 10.collect({rrand(0.2, 0.8)}),
	argFreqs: 10.collect({rrand(400, 1200.2)}),
	argAmps: 10.collect({rrand(0.1, 0.15)})
);

tasks[\randomDense] = taskFunction.value(
	argTimes: 200.collect({rrand(0.05, 0.2)}),
	argFreqs: 200.collect({rrand(400, 1200.2)}),
	argAmps: 200.collect({rrand(0.1, 0.15)})
);

tasks[\bassGrooves] = taskFunction.value(
	argTimes: 200.collect({rrand(0.02, 0.1)}),
	argFreqs: 200.collect({rrand(40, 120.2)}),
	argAmps: 200.collect({rrand(0.1, 0.15)})
);

//prepare window and layout
window = Window.new("task player").front; //put window to front right away
layout = VLayout.new;
window.layout_(layout);

allButtons = tasks.collect({|thisTask, thisTaskName|
	var note, filename, button;
	// filename = thisBuffer.path.basename;
	// filename.postln; //just the filename, without full path, use for display
	layout.add(//add the button to the layout
		button = Button(window)
		.states_([[thisTaskName], [thisTaskName ++ " playing"]])
		.action_({|buttonObject|
			buttonObject.value.postln;
			if(buttonObject.value.asBoolean, {
				thisTask.play;
				// allButtons.do({|thisButt|
				// 	if(thisButt != button, {
				// 		thisButt.valueAction_(0);
				// 	})
				// });
			}, {
				thisTask.stop;
				thisTask.reset;
			});
		});
	);
	button;//IMPORTANT - this will go to allButtons
});

//
// window.view.keyUpAction_({|thisView, char, modifiers, unicode, keycode, key|
// 	var thisIndex, thisButton;
// 	[char, modifiers, unicode, keycode, key].postln;
// 	// char.class.postln;
// 	// thisIndex = mappingDictionary[char];
// 	thisIndex = unicode - 49; //49 is unicode for number 0
// 	"thisIndex: ".post; thisIndex.postln;
// 	thisButton = allButtons[thisIndex];
// 	"thisButton.value.asBoolean: ".post; thisButton.value.booleanValue.postln;
// 	if(thisButton.value.booleanValue, {
// 		thisButton.valueAction = 0;
// 		}, {
// 			thisButton.valueAction = 1;
// 	});
// });

window.onClose_({
	tasks.do({|thisTask|
		thisTask.stop;
	});
});

)


//--------------------------------------------------
// using GUI to control tasks, now with a slider and some parameters
//--------------------------------------------------


(
var taskFunction, tasks, synth;
var window, layout, allButtons, allSliders;

tasks = IdentityDictionary.new;//create a dictionary for storing individual tasks

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

taskFunction = {arg argTimes, argFreqs, argAmps, modSlider; //note extra argument here
	Task({
		argTimes.size.do({arg inc;
			"current time diff: ".post; argTimes[inc].postln;
			argTimes[inc].wait; //wait for a specified time
			{
				synth.note(0, 2.0).freq_(
					argFreqs[inc] + (modSlider.value * 2000)
				).envDur_(2).amp_(argAmps[inc]).play; //0 as startTime, and .play it
			}.defer; //needed here, since we take the value of a slider inside the task!
		});
	});
};//note change of variable/argument names, just for clarity times -> argTimes, freqs -> argFreqs etc

//prepare window and layout
window = Window.new("simple player").front; //put window to front right away
layout = VLayout.new;
window.layout_(layout);

//create sliders first

allSliders = 1.collect({
	Slider.new(window).orientation_(\horizontal)
}); //create sliders separately

tasks[\first] = taskFunction.value(
	argTimes: [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ],
	argFreqs: [420, 440, 440, 548, 332, 656, 424, 564, 816, 412],
	argAmps: [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2],
	modSlider: allSliders[0]
);

tasks[\random] = taskFunction.value(
	argTimes: 10.collect({rrand(0.2, 0.8)}),
	argFreqs: 10.collect({rrand(400, 1200.2)}),
	argAmps: 10.collect({rrand(0.1, 0.2)}),
	modSlider: allSliders[0]
);

tasks[\randomDense] = taskFunction.value(
	argTimes: 200.collect({rrand(0.05, 0.2)}),
	argFreqs: 200.collect({rrand(400, 1200.2)}),
	argAmps: 200.collect({rrand(0.1, 0.2)}),
	modSlider: allSliders[0]
);


allButtons = tasks.collect({|thisTask, thisTaskName|
	var note, filename, button, slider;
	// filename = thisBuffer.path.basename;
	// filename.postln; //just the filename, without full path, use for display
	layout.add(//add the button to the layout
		button = Button(window)
		.states_([[thisTaskName], [thisTaskName ++ " playing"]])
		.action_({|buttonObject|
			buttonObject.value.postln;
			if(buttonObject.value.asBoolean, {
				thisTask.play;
			}, {
				thisTask.stop;
				thisTask.reset;
			});
		}),
	);
	[button, slider];//IMPORTANT - this will go to allButtons
});

layout.add(allSliders[0]);//add the slider at the bottom

layout.add(nil);//and some empty space at the bottom

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

window.onClose_({
	tasks.do({|thisTask|
		thisTask.stop;
	});
});

)
