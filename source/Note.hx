package;

import flixel.FlxSprite;
import shaders.ColorSwap;
import ui.PreferencesMenu;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	private var willMiss:Bool = false;

	public var altNote:Bool = false;
	public var invisNote:Bool = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var colorSwap:ColorSwap;
	public var noteScore:Float = 1;
	public var distance:Float = 2000;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public static var arrowColors:Array<Float> = [1, 1, 1, 1];

	inline private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		// trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) // haha funny twitter shit
	{
		if (isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;

		this.noteData = noteData;

		var daStage:String = PlayState.curStage;

		switch (daStage)
		{
			case 'school' | 'schoolEvil':
				loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);

				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);

				if (isSustainNote)
				{
					loadGraphic(Paths.image('weeb/pixelUI/arrowEnds'), true, 7, 6);

					animation.add('purpleholdend', [4]);
					animation.add('greenholdend', [6]);
					animation.add('redholdend', [7]);
					animation.add('blueholdend', [5]);

					animation.add('purplehold', [0]);
					animation.add('greenhold', [2]);
					animation.add('redhold', [3]);
					animation.add('bluehold', [1]);
				}

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();

			default:
				frames = Paths.getSparrowAtlas('NOTE_assets');

				animation.addByPrefix('greenScroll', 'green instance');
				animation.addByPrefix('redScroll', 'red instance');
				animation.addByPrefix('blueScroll', 'blue instance');
				animation.addByPrefix('purpleScroll', 'purple instance');

				animation.addByPrefix('purpleholdend', 'pruple end hold');
				animation.addByPrefix('greenholdend', 'green hold end');
				animation.addByPrefix('redholdend', 'red hold end');
				animation.addByPrefix('blueholdend', 'blue hold end');

				animation.addByPrefix('purplehold', 'purple hold piece');
				animation.addByPrefix('greenhold', 'green hold piece');
				animation.addByPrefix('redhold', 'red hold piece');
				animation.addByPrefix('bluehold', 'blue hold piece');

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = PreferencesMenu.getPref('antialiasing');

				// colorSwap.colorToReplace = 0xFFF9393F;
				// colorSwap.newColor = 0xFF00FF00;

				// color = FlxG.random.color();
				// color.saturation *= 4;
				// replaceColor(0xFFC1C1C1, FlxColor.RED);
		}

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		updateColors();

		switch (noteData)
		{
			case 0:
				x += swagWidth * 0;
				if (!isSustainNote)
					animation.play('purpleScroll');
			case 1:
				x += swagWidth * 1;
				if (!isSustainNote)
					animation.play('blueScroll');
			case 2:
				x += swagWidth * 2;
				if (!isSustainNote)
					animation.play('greenScroll');
			case 3:
				x += swagWidth * 3;
				if (!isSustainNote)
					animation.play('redScroll');
		}

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			noteScore * 0.2;
			alpha = 0.6;

			if (PreferencesMenu.getPref('downscroll'))
				angle = 180;

			x += width / 2;

			switch (noteData)
			{
				case 2:
					animation.play('greenholdend');
				case 3:
					animation.play('redholdend');
				case 1:
					animation.play('blueholdend');
				case 0:
					animation.play('purpleholdend');
			}

			updateHitbox();

			x -= width / 2;

			if (PlayState.curStage.startsWith('school'))
				x += 30;

			if (prevNote.isSustainNote)
			{
				switch (prevNote.noteData)
				{
					case 0:
						prevNote.animation.play('purplehold');
					case 1:
						prevNote.animation.play('bluehold');
					case 2:
						prevNote.animation.play('greenhold');
					case 3:
						prevNote.animation.play('redhold');
				}

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	public function updateColors():Void
	{
		colorSwap.update(arrowColors[noteData]);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			// miss on the NEXT frame so lag doesnt make u miss notes
			if (willMiss && !wasGoodHit)
			{
				tooLate = true;
				canBeHit = false;
			}
			else
			{
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset)
				{ // The * 0.5 is so that it's easier to hit them too late, instead of too early
					if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
						canBeHit = true;
				}
				else
				{
					canBeHit = true;
					willMiss = true;
				}
			}
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
