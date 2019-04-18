//network communication

//you can use Open Sound Control protocol to exchange data with other software and other computers

//recall the iPad TouchOSC examples... this time we'll do it both ways

//we￼ need to be on the same network (usually campus wifi is fine, but not recommended for a performance)
//we need to know our IP addres and port SC is listening on
NetAddr.myIP; //this is important if you're talking to another computer; if you're on the same computer, use "localhost" or "127.0.0.1" as an address
NetAddr.langPort; //this needs to be set in your sending application

//NOTE: language port might change... the best is to have a way to set the port of the other end during run time... more on that later

//let's start with Processing (processing.org)

//we'll use oscP5 library

//open and run oscP5sendReceive_SC.pde sketch
//trace to see what we're getting
OSCFunc.trace(true, true);

//now click on the sketch window

//your post window should read something like
/*
OSC Message Received:
	time: 2679.225931044
	address: a NetAddr(127.0.0.1, 52700)
	recvPort: 57120
	msg: [ /test, 123 ]
*/

//turn off trace
OSCFunc.trace(false);

// ---------------------------------------
// ------------ receiving from Processing ----
// ---------------------------------------

//use a proper responder
(
~myResponder = OSCdef(\test, {arg msg;
	var val;
	"I received a message!".postln;
	msg.postln;
	val = msg[1..];
	val.postln;
}, '/test') //note we specify path, needs to be the same as in processing
);
~myResponder.free;


//and a sound example
(
~synth = CtkSynthDef(\SimpleSineEnv, {|freq = 440, amp = 0.2|
	Out.ar(0, SinOsc.ar(freq, 0, amp) * EnvGen.kr(Env.perc, doneAction: 2))
});
~myResponder = OSCdef(\test, {arg msg;
	var val;
	"I received a message!".postln;
	// msg.postln;
	val = msg[1];
	val.postln;
	~synth.note.freq_(rrand(50, 70).midicps).play;
}, '/test') //note we specify path, needs to be the same as in processing
);
~myResponder.free;


// ---------------------------------------
// ------------ sending to Processing --------
// ---------------------------------------

//look at the processing console, then run the code below
(
~addr = NetAddr.new("localhost", 12000); //port needs to be set to this one on the receiving side

//sending:
~addr.sendMsg('/somePath', 1);
~addr.sendMsg('/anotherPath', "something");
)
