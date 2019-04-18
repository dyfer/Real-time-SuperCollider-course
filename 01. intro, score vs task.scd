// DX463 - Class 1


//----------------------------------------------------------------
//Maintaining SC installation
//----------------------------------------------------------------

//SC Version
//Current (10.2015) SC version is 3.7a

//Quarks
//New system...
Quarks.gui

//Extensions and stuff
//Usually don't need to deal with it, until you install a new quark and the library doesn't recompile
//on OS X it lives in /Users/<yourUserName>/Library/Application Support/SuperCollider
Platform.userAppSupportDir //see here
Platform.userAppSupportDir.openOS //open it in the file manager
//outside SC (e.g. if SuperCollider doesn't start or the library doesn't compile): in Finder menu Go, press Alt, Library will show up

//try it!

//there you can remove or temporarily move extensions that cause trouble

//you might want to move/remove contents of this folder when you reinstall/upgrade SuperCollider


//----------------------------------------------------------------
//Effective work with SC's IDE (Integrated Development Environment)
//----------------------------------------------------------------

//use code blocks, evaluate with Apple-Return
(
var something;
something = "nothing"; //a string
something = something ++ " but takes few lines to be created"; //concatenation
something.postln;
)
//as opposed to
var something;
something = "nothing"; //a string
something = something ++ " but takes few lines to be created"; //concatenation
something.postln;

//use keyboard shortcuts; see menus and SuperCollider -> Preferences (Apple-,)

//look into help files and online for solutions :)

//use split view for large files (View -> Split to right)



//----------------------------------------------------------------
//Coding practices
//----------------------------------------------------------------

//use comments

//keep it organized: e.g. input data together, setting parameters together
//also group variable declarations

//avoid global variables! (except for prototyping)

//use code blocks

//avoid copying and pasting code... iterate instead

//free necessary things and reload on each run
//what needs to be freed?

//useful: syntax shortcuts
HelpBrowser.openHelpFor("Syntax Shortcuts")
//and
HelpBrowser.openHelpFor("Symbolic Notations")



//----------------------------------------------------------------
//Scheduling
//----------------------------------------------------------------

//Examples borrowed from the SuperCollider book: Clock, Routine, Task

// Clock examples

SystemClock.sched(2, {"foo".postln; });

// "foo" repeats every second
SystemClock.sched(0, {"foo".postln; 1.0 });

// "bar" repeats at a random delay
SystemClock.sched(0, {"bar".postln; 1.0.rand });

// clear all scheduled events
SystemClock.clear;

//TempoClock
(
t = TempoClock.new; // make a new TempoClock
t.sched(0, {"Hello!".postln; 1});
)
t.tempo = 2; // twice as fast
t.clear;

// Routine
(
r = Routine({
"foo".yield;
"bar".yield;
});
)
r.value; // foo
r.value; // bar
r.value; // we've reached the end, so it returns nil
r.next;//same thing

// Routine in a Clock
(
r = Routine({
	"foo".postln;
	1.yield; // reschedule after 1 second
	"bar".postln;
	1.yield;
	"foobar".postln;
});
SystemClock.sched(0, r);
)

// yield as musical fermata
s.boot;
(
SynthDef(\default, {arg out = 0, freq = 440, amp = 0.5, pan = 0;
	var snd, env;
	snd = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(Env.perc, doneAction: 2);
	Out.ar(out, Pan2.ar(snd * env, pan));
}).add;
r = Routine({
	x = Synth(\default, [freq: 76.midicps]);
	0.3.wait;

	x = Synth(\default, [freq: 74.midicps]);
	0.3.wait;

	x = Synth(\default, [freq: 73.midicps]);
	0.3.wait;

	y = Synth(\default, [freq: 71.midicps]);
	"Waiting...".postln;
	nil.yield;// fermata

	z = Synth(\default, [freq: 69.midicps]);

});
)
// do this then wait for the fermata
r.play;
// finish
r.play;

//reset
r.reset //now you can play again


// Using Task so you can pause the sequence
(
t = Task({
	loop({	 // loop the whole thing
		3.do({	 // do this 3 times
			x = Synth(\default, [freq: 76.midicps]);
			0.5.wait;
			x = Synth(\default, [freq: 73.midicps]);
			0.5.wait;
		});
		"I'm waiting for you to resume".postln;
		nil.yield;// fermata
		x = Synth(\default, [freq: 69.midicps]);
		1.wait;
	});
});
)
t.play;
t.resume;
t.stop;
t.reset;



// Nesting tasks inside routines
(
r = Routine({
	c = TempoClock.new; // make a TempoClock
	// start a loop
	t = Task({
		loop({
			x = Synth(\default, [freq: 61.midicps, amp: 0.2]);
			0.2.wait;
			x = Synth(\default, [freq: 67.midicps, amp: 0.2]);
			rrand(0.075, 0.25).wait; // random wait from 0.1 to 0.25 seconds
		});
	}, c); // use the TempoClock to play this Task
	t.start;
	nil.yield;

	// now add some notes
	y = Synth(\default, [freq: 73.midicps, amp: 0.3]);
	nil.yield;
	y = Synth(\default, [freq: 79.midicps, amp: 0.3]);
	c.tempo = 2; // double time
	nil.yield;
	t.stop; // stop the Task and Synths
});
)

r.next; // start loop
r.next; // first note
r.next; // second note; loop goes 'double time'
r.next; // stop loop


//--------
// Task examples with CtkSynthDef
(
a = CtkSynthDef(\simple, {arg out = 0, freq = 440, amp = 0.5, pan = 0;
	var snd, env;
	snd = SinOsc.ar(freq, 0, amp);
	env = EnvGen.kr(Env.perc, doneAction: 2);
	Out.ar(out, Pan2.ar(snd * env, pan));
})
)

a.note.play;
(
t = Task({
	10.do({|i|
		a.note.amp_(-9.dbamp).play;
		0.2.wait;
	});
}).play;
)
(
t = Task({
	10.do({|i|
		a.note.freq_(rrand(440, 450)).amp_(-9.dbamp).play;
		0.2.wait;
	});
}).play
)
(
t = Task({
	10.do({|i|
		a.note.freq_(rrand(440, 1450)).amp_(-9.dbamp).play;
		0.2.wait;
	});
}).play
)
(
t = Task({
	10.do({|i|
		a.note.freq_(rrand(440, 1450)).amp_(-9.dbamp).play;
		(0.1 + 0.1.rand).wait;
	});
}).play
)
(
t = Task({
	100.do({|i|
		a.note.freq_(rrand(440, 1450)).amp_(-18.dbamp).play;
		(0.01 + 0.05.rand).wait;
	});
}).play
)
(
t = Task({
	100.do({|i|
		a.note.freq_(rrand(40, 6450)).amp_(-18.dbamp).play;
		(0.01 + 0.05.rand).wait;
	});
}).play
)
(
t = Task({
	100.do({|i|
		a.note.freq_(rrand(40 + (i * 20), 450 + (i*40))).amp_(-22.dbamp).play;
		(0.01 + 0.05.rand).wait;
	});
}).play
)
(
t = Task({
	1000.do({|i|
		a.note.freq_(rrand(40 + (i * 5), 450 + (i*10))).amp_(-28.dbamp).play;
		(0.01 + 0.02.rand).wait;
	});
}).play
)
t.stop;
t.play;


//now the same things in a code block, without global variables (e.g. if you'd like to use it for the performance):
(
var synth, task;
s.waitForBoot({
	synth = CtkSynthDef(\simple, {arg out = 0, freq = 440, amp = 0.5, pan = 0;
		var snd, env;
		snd = SinOsc.ar(freq, 0, amp);
		env = EnvGen.kr(Env.perc, doneAction: 2);
		Out.ar(out, Pan2.ar(snd * env, pan));
	});
	task = Task({
		1000.do({|i|
			synth.note.freq_(rrand(40 + (i * 5), 450 + (i*10))).amp_(-28.dbamp).play;
			(0.01 + 0.02.rand).wait;
		});
	});
	Task({
		task.play;
		5.wait;
		task.stop;
		1.wait;
		task.play;
	}).play;
	// t = task; //this is only so we can gracetully stop if from outside the code block... it's one justified use of a global variable, but there are also other solutions to the problem of controlling things while they run - will be presented in the future;
});
)

//task from a function
(
var synth, task;
s.waitForBoot({
	synth = CtkSynthDef(\simple, {arg out = 0, freq = 440, amp = 0.5, pan = 0;
		var snd, env;
		snd = SinOsc.ar(freq, 0, amp);
		env = EnvGen.kr(Env.perc, doneAction: 2);
		Out.ar(out, Pan2.ar(snd * env, pan));
	});
	task = {|iterations = 1000, minWaitTime = 0.01|
		Task({
			iterations.do({|i|
				synth.note.freq_(rrand(40 + (i * 5), 450 + (i*10))).amp_(-28.dbamp).play;
				(minWaitTime + 0.02.rand).wait;
			});
		});
	};
	Task({
		var taskInstance; //local variable inside this function (which is inside this task)
		task.value(100, 0.12).play;
		5.wait;
		taskInstance = task.value(1000, 0.01).play;
		1.wait;
		taskInstance.stop;
		2.wait;
		taskInstance.play;
	}).play;
	// task.value(10, 0.2).play;
	// t = task; //this is only so we can gracetully stop if from outside the code block... it's one justified use of a global variable, but there are also other solutions to the problem of controlling things while they run - will be presented in the future;
});
)


t.stop;//just in case

//see also
HelpBrowser.openHelpFor("Task")



//----------------------------------------------------------------
//Debugging
//----------------------------------------------------------------

1.sqpt  // no class implements this method; therefore you'll get an error
Task.new.jumpUpsideDown

[1, 2, 3, 4].at(1);

"I'm just a string";;

(
"I'm a string".postln
1+2;
)

//and now if it's like
(
"there is something looooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong beforehand";
"I'm a very very very very very very very very very very very very very string".postln //and have a comment at the end
1+2;
)
//it might be more confusing, but it's the same error.


//----------------------------------------------------------------
//(Ctk)Score to Task
//----------------------------------------------------------------
//Converting score-based (non-realtime - NRT) examples to realtime for live performance etc.

//first, review how tasks and routines work
"Routines and Tasks".help; //choose "15. Sequencing with Routines and Tasks"

// ------------------------------------------
// ---------------- 1 - score -----------------
// ------------------------------------------

//for conversion - a simple score example
s.boot;
(
var score, synth, options;
// create a CtkScore to fill with notes
score = CtkScore.new;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});
score.add(synth.note(0.2, 2.0).freq_(420).envDur_(2).amp_(0.5)); //first start time is 0.2 to allow for loading the synthdef
score.add(synth.note(1.0, 2.0).freq_(440).envDur_(2).amp_(0.5));
score.add(synth.note(3.0, 2.0).freq_(440).envDur_(2).amp_(0.2));
score.add(synth.note(3.1, 2.0).freq_(548).envDur_(2).amp_(0.2));
score.add(synth.note(3.2, 2.0).freq_(332).envDur_(2).amp_(0.2));
score.add(synth.note(3.3, 2.0).freq_(656).envDur_(2).amp_(0.2));
score.add(synth.note(3.4, 2.0).freq_(424).envDur_(2).amp_(0.2));
score.add(synth.note(3.5, 2.0).freq_(564).envDur_(2).amp_(0.2));
score.add(synth.note(3.6, 2.0).freq_(816).envDur_(2).amp_(0.2));
score.add(synth.note(5.1, 2.0).freq_(412).envDur_(2).amp_(0.2));
score.play;
)

// --------------------------------------------
// ---------------- 1 - realtime -----------------
// --------------------------------------------

//now, to convert it to realtime, we need to
//- schdule notes using a Task
//- .wait (or .yield) between events/notes; we need to provide time differences, as opposed to absolute times since the start of the piece
//- play notes right away (start time = 0 and ".play" it)
s.reboot;
(
var task, synth, options;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
		var osc, osc2, env;
		osc = SinOsc.ar(freq, 0, amp);
		env = Line.kr(1, 0, envDur, doneAction: 0);
		Out.ar(0, osc * env)
	});
task = Task({
	0.2.wait; //wait for 0.2 seconds; same as 0.2.yield
	synth.note(0, 2.0).freq_(420).envDur_(2).amp_(0.5).play; //play the note right away
	0.8.wait; //wait
	synth.note(0, 2.0).freq_(440).envDur_(2).amp_(0.5).play; //play etc.
	2.wait;
	synth.note(0, 2.0).freq_(440).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(548).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(332).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(656).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(424).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(564).envDur_(2).amp_(0.2).play;
	0.1.wait;
	synth.note(0, 2.0).freq_(816).envDur_(2).amp_(0.2).play;
	1.5.wait;
	synth.note(0, 2.0).freq_(412).envDur_(2).amp_(0.2).play;
});

task.play; //play the task
)


// ------------------------------------------
// ---------------- 2 - score -----------------
// ------------------------------------------

//when you use functions to generate notes, it makes it even easier to conert code from NRT to realtime
//score example
(
var score, synth, options, startTimes, freqs, amps;
// create a CtkScore to fill with notes
score = CtkScore.new;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});
startTimes = [0.2, 1.0, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.1];
freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

startTimes.size.do({arg inc;
	score.add(synth.note(startTimes[inc], 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]));
});
score.play;
)


// --------------------------------------------
// ---------------- 2 - realtime-----------------
// --------------------------------------------

//now converted to realtime
//if needed, conversion to relative times can be done programmatically
//(but often times you'll already have that data, see below)
(
var task, synth, options, startTimes, startTimesRelative, freqs, amps;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});

startTimes = [0.2, 1.0, 3.0, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.1];
freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

startTimesRelative = startTimes.collect({arg thisStartTime, inc;
	var thisRelativeStartTime, previousStartTime;
	previousStartTime = startTimes[inc-1];
	if(previousStartTime.notNil, {//first check if we can get precious start time
		thisRelativeStartTime = thisStartTime - previousStartTime; //if so, subtract previous from current
	}, {
		thisRelativeStartTime = thisStartTime; //if not, treat it as the first start time, don's subtract anythin
	});
	thisRelativeStartTime; //important - return thisRelativeStartTime, so .collect will return an array of these
});
"startTimesRelative: ".post; startTimesRelative.postln;

task = Task({
	startTimesRelative.size.do({arg inc;
		"waiting ".post; startTimesRelative[inc].post; "s".postln; //since we're in realtime, we can post things as they happen
		startTimesRelative[inc].wait; //wait
		"playing sound at frequency ".post; freqs[inc].post; "Hz".postln;
		synth.note(0, 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]).play; //startTime = 0, .play right away
	});
});
task.play; //play the task
)

// ------------------------------------------
// ---------------- 3 - score -----------------
// ------------------------------------------

//often we think about time in relative values between items, for example:
(
var score, synth, options, times, freqs, amps, now;
// create a CtkScore to fill with notes
score = CtkScore.new;

synth = CtkSynthDef(\oscili,  {arg freq, amp, envDur;
	var osc, osc2, env;
	osc = SinOsc.ar(freq, 0, amp);
	env = Line.kr(1, 0, envDur, doneAction: 0);
	Out.ar(0, osc * env)
});
times = [ 0.2, 0.8, 2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.5 ]; //relative times
freqs = [420, 440, 440, 548, 332, 656, 424, 564, 816, 412];
amps = [0.5, 0.5, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2];

now = 0; //initialize variable to keep the time information

times.size.do({arg inc;
	now = now + times[inc]; //increment time by the relative time value
	"now: ".post; now.postln;
	score.add(synth.note(now, 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc])); //use now as startTime
});
score.play;
)

// --------------------------------------------
// ---------------- 3 - realtime -----------------
// --------------------------------------------

//and then coverting to realtime is even easier
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

//no need to have incremented "now" variable

task = Task({
	times.size.do({arg inc;
		"current time diff: ".post; times[inc].postln;
		times[inc].wait; //wait for a specified time
		synth.note(0, 2.0).freq_(freqs[inc]).envDur_(2).amp_(amps[inc]).play; //0 as startTime, and .play it
	});
});
task.play;//play the dask
)




//----------------------------------------------------------------
//HOMEWORK
//----------------------------------------------------------------

