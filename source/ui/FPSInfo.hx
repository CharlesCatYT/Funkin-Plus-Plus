package ui;

import haxe.Timer;
import openfl.Lib;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FPSInfo extends TextField
{
	public var showFPS:Bool = true;
	public var showMemory:Bool = true;
	public var showMemoryPeak:Bool = true;
	public var isShowingBoth:Bool = true;

	var times:Array<Float> = [];
	var memoryPeak:Float = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		width = Lib.current.stage.width;

		selectable = false;
		mouseEnabled = false;

		defaultTextFormat = new TextFormat(Paths.font("vcr.ttf"), 13, color);
		multiline = true;
		text = "FPS: ";

		addEventListener(Event.ENTER_FRAME, onEnter);
	}

	function onEnter(_)
	{
		var now:Float = Timer.stamp();
		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;
		if (mem > memoryPeak)
			memoryPeak = mem;

		if (visible)
		{
			text = "";

			if (showFPS)
				text += "FPS: " + times.length + "\n";

			if (showMemory)
			{
				text += "MEM: " + mem + "mb";
				if (showMemoryPeak)
					text += " / " + memoryPeak + "mb";
			}
			text += '\nFriday Night Funkin\' PlusPlus v0.1.0';

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
			text += "\n"; 
		}
	}
}