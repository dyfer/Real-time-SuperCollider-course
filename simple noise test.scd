s.options.numOutputBusChannels_(32);
s.reboot;
x = {PinkNoise.ar(-12.dbamp)}.play(outbus: 0);
x.free;
