//import flixel.text.FlxBitmapText;
//import flixel.graphics.frames.FlxBitmapFont; Ok it doesnt work
/*
TODO
- readd clipping for song header (idk how do that)
- cleanup
- seriously, cleanup
- do it already stupid girl
- fix other stuff
*/
import Main;
import flixel.effects.FlxFlicker;
import flixel.sound.FlxSound;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import backend.CustomFadeTransition;
import tjson.TJSON as JSON;
import flixel.util.FlxSave;
import backend.CoolUtil;
import backend.MusicBeatState;
import flixel.addons.transition.FlxTransitionableState;
import backend.WeekData;
import backend.Highscore;
import backend.Difficulty;
import states.FreeplayState;
import states.StoryMenuState;
import flixel.math.FlxBasePoint;
import flixel.group.FlxTypedSpriteGroup;

var characters:String = 'AaBbCcDdEeFfGgHhiIJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz:1234567890';

var grpStickers = null;
var grpInfoTexts = null;

var subTimers:Array = []; //timers to cancel before destroying state
var diffText:FlxSprite = null;
var lastAlpha:FlxSprite = null;
var heartsPerfect:FlxAnimate = null;
var resultsBf = null;
var resultsGf = null;
var currentTally = -1;
var tallies:Array = [];
var shownResults:Bool = false;
var inResults:Bool = false;
var resultsActive:Bool = false;
var resultsMusic = null;
var introSound = null;
var rankDelay:Map = [
	'PERFECT' => {music: 95 / 24, flash: 129 / 24, bf: 95 / 24, hi: 140 / 24},
	'EXCELLENT' => {music: 0, flash: 122 / 24, bf: 95 / 24, hi: 140 / 24}, //its 97/24 but it wouldnt sync ;(
	'GREAT' => {music: 5 / 24, flash: 109 / 24, bf: 95 / 24, hi: 129 / 24},
	'GOOD' => {music: 3 / 24, flash: 107 / 24, bf: 95 / 24, hi: 127 / 24},
	'SHIT' => {music: 2 / 24, flash: 186 / 24, bf: 95 / 24, hi: 207 / 24},
];

var stickerImages:Array = [];
var stickerSounds:Array = [];

var maxCombo:Int = 0;
var totalHits:Int = 0;
var totalNotes:Int = 0;
var campaignScore:Int = 0;

function onCreatePost() {
	//for (note in game.unspawnNotes) if (note.mustPress && !note.isSustainNote) totalNotes ++;
	for (asset in ['resultBoyfriendGOOD', 'results', 'soundSystem', 'score-digital-numbers', 'tallieNumber',
	'resultGirlfriendGOOD', 'scorePopin', 'ratingsPopin', 'highscoreNew', 'clearPercent/clearPercentNumberSmall'])
		Paths.getSparrowAtlas('resultScreen/' + asset);
	for (asset in ['alphabet']) Paths.image('resultScreen/' + asset);
	Paths.music('resultsNORMAL');
	//get rid of story mode save when starting a week, in case of unexpected song exit
	if (PlayState.isStoryMode) {
		var weekSongs = WeekData.getCurrentWeek().songs;
		if (PlayState.SONG.song.toLowerCase() == weekSongs[0][0].toLowerCase()) {
			var save:FlxSave = new FlxSave();
			save.bind('_storymode', CoolUtil.getSavePath() + '/psychenginemods');
			save.erase();
			save.flush();
		}
	}
	precacheStickers();
	return;
}
function precacheStickers() {
	var stickersPath:String = Paths.modFolders('images/transitionSwag/');
	if (FileSystem.exists(stickersPath)) {
		for (sub in FileSystem.readDirectory(stickersPath)) {
			var jsonPath = stickersPath + sub + '/stickers.json';
			if (FileSystem.exists(jsonPath)) {
				var content = File.getContent(jsonPath);
				var json = JSON.parse(content);
				var stickers = json.stickers;
				for (sticker in Reflect.fields(stickers)) {
					var images = Reflect.field(stickers, sticker);
					if (images == null) continue;
					for (image in images) { //jesus
						var sticky:String = 'transitionSwag/' + sub + '/' + image;
						stickerImages.push(sticky);
						Paths.image(sticky);
					}
				}
			}
		}
	}
	var funny:FlxSprite = new FlxSprite(100, 100).loadGraphic(Paths.image('icons/icon-dad'));
	var soundsPath:String = Paths.modFolders('sounds/stickersounds/');
	if (FileSystem.exists(soundsPath)) {
		for (sub in FileSystem.readDirectory(soundsPath)) {
			if (FileSystem.isDirectory(soundsPath + sub)) {
				for (snd in FileSystem.readDirectory(soundsPath + sub)) {
					var soundPath:String = 'stickersounds/' + sub + '/' + snd;
					var dot = soundPath.lastIndexOf('.');
					soundPath = soundPath.substring(0, dot < 0 ? soundPath.length : dot);
					var sound = Paths.sound(soundPath);
					if (sound != null) stickerSounds.push(sound);
				}
			}
		}
	}
}
function goodNoteHit(note) {
	if (!note.hitCausesMiss && !note.isSustainNote) totalHits ++;
	maxCombo = Math.max(maxCombo, game.combo);
	return;
}
function onEndSong() {
	if (ClientPrefs.getGameplaySetting('botplay') || ClientPrefs.getGameplaySetting('practice')) return;
	if (PlayState.isStoryMode && PlayState.storyPlaylist.length > 1) {
		var save:FlxSave = new FlxSave();
		save.bind('_storymode', CoolUtil.getSavePath() + '/psychenginemods');
		//campaignScore acted weird?? for some fuckin reason???
		if (save.data.score == null) save.data.score = 0; save.data.score += game.songScore;
		if (save.data.hits == null) save.data.hits = 0; save.data.hits += totalHits;
		if (save.data.sicks == null) save.data.sicks = 0; save.data.sicks += game.ratingsData[0].hits;
		if (save.data.goods == null) save.data.goods = 0; save.data.goods += game.ratingsData[1].hits;
		if (save.data.bads == null) save.data.bads = 0; save.data.bads += game.ratingsData[2].hits;
		if (save.data.shits == null) save.data.shits = 0; save.data.shits += game.ratingsData[3].hits;
		if (save.data.maxCombo == null) save.data.maxCombo = 0; save.data.maxCombo = Math.max(save.data.maxCombo, maxCombo);
		save.flush();
		
		return;
	}
	if (shownResults) return;
	
	if (PlayState.isStoryMode) {
		var save:FlxSave = new FlxSave();
		save.bind('_storymode', CoolUtil.getSavePath() + '/psychenginemods');
		totalHits += (save.data.hits != null ? save.data.hits : 0);
		campaignScore = game.songScore + (save.data.score != null ? save.data.score : 0);
		game.ratingsData[0].hits += (save.data.sicks != null ? save.data.sicks : 0);
		game.ratingsData[1].hits += (save.data.goods != null ? save.data.goods : 0);
		game.ratingsData[2].hits += (save.data.bads != null ? save.data.bads : 0);
		game.ratingsData[3].hits += (save.data.shits != null ? save.data.shits : 0);
		if (save.data.maxCombo != null) maxCombo = Math.max(save.data.maxCombo, maxCombo);
		save.erase();
		save.flush();
		PlayState.campaignScore = campaignScore;
	}
	
	var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
	game.checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
	shownResults = true;
	
	if (game.gf != null) game.camFollow.setPosition(game.gf.getMidpoint().x, game.gf.getMidpoint().y);
	var fade:FlxSprite = new FlxSprite(FlxG.width * .5, FlxG.height * .5).makeGraphic(1, 1, 0xff000000);
	fade.scale.set(FlxG.width * 2, FlxG.height * 2);
	fade.scrollFactor.set();
	fade.alpha = 0;
	game.playbackRate = 1;
	game.add(fade);
	FlxTween.tween(fade, {alpha: 1}, 1);
	FlxTween.tween(game.camHUD, {alpha: 0}, 1);
	new FlxTimer().start(1.5, () -> {
		game.remove(fade);
		resultsScreen(game);
		game.paused = true;
		//CustomSubstate.openCustomSubstate('results');
	});
	return Function_Stop;
}

function stickers(inst) {
	var grpStickers = new FlxTypedSpriteGroup();
	grpStickers.scrollFactor.set();
	grpStickers.camera = game.camOther;
	
	var xPos:Float = -100;
	var yPos:Float = -100;
	while (xPos <= FlxG.width + 100) {
		var randomSticky:String = stickerImages[FlxG.random.int(0, stickerImages.length - 1)];
		var stickerSprite:FlxSprite = new FlxSprite(xPos, yPos).loadGraphic(Paths.image(randomSticky));
		//stickerSprite.origin.set(stickerSprite.frameWidth * .5, stickerSprite.frameHeight * .5);
		stickerSprite.visible = false;
		stickerSprite.antialiasing = ClientPrefs.data.antialiasing;
		stickerSprite.angle = FlxG.random.int(-60, 70);
		grpStickers.add(stickerSprite);
		
		xPos += Math.max(stickerSprite.frameWidth * .5, 50);
		if (xPos >= FlxG.width + 100) {
			if (yPos <= FlxG.height + 100) {
				xPos = -100;
				yPos += FlxG.random.float(70, 120);
			}
		}
	}
	shuffleArray(grpStickers.members);
	var i:Int = 0;
	for (sticker in grpStickers.members) {
		var timing = FlxMath.remapToRange(i, 0, grpStickers.members.length, 0, 0.9);
		var isLast:Bool = (i >= grpStickers.members.length - 1);
		new FlxTimer().start(timing, () -> {
			if (grpStickers == null) return;
			FlxG.sound.play(inArray(stickerSounds, 0, stickerSounds.length - 1));
			sticker.visible = true;
			var frameTimer:Int = FlxG.random.int(0, 2);
			if (isLast) frameTimer = 2;
			new FlxTimer().start((1 / 24) * frameTimer, () -> {
				sticker.scale.x = sticker.scale.y = FlxG.random.float(0.97, 1.02);
				if (isLast) {
					new FlxTimer().start(.5, () -> resultsClose(inst));
				}
			});
		});
		i ++;
	}
	inst.add(grpStickers);
	var lastOne = inArray(grpStickers.members, grpStickers.members.length - 1);
	if (lastOne != null) {
		lastOne.updateHitbox();
		lastOne.screenCenter();
		lastOne.angle = 0;
	}
}
function shuffleArray(array) {
	var maxValidIndex = array.length - 1;
	for (i in 0...maxValidIndex) {
		var j = FlxG.random.int(i, maxValidIndex);
		var tmp = inArray(array, i);
		setArray(array, i, inArray(array, j));
		setArray(array, j, tmp);
	}
}
var prevRating:Int = -1;
var scrollV:FlxBackdrop;
var scrollHA:FlxTypedSpriteGroup;
var scrollHB:FlxTypedSpriteGroup;
var clearnumGrp:FlxTypedSpriteGroup;
var clearImage:FlxSprite;
var bg:FlxSprite;
var soundSystem:FlxSprite;
var scrollRad:Float = 0;
var scrollWidth:Float = 0;
function updateClearNums(inst, rating, target) {
	var n = Math.floor(rating);
	if (prevRating < n) {
		var done:Bool = (n == target);
		FlxG.sound.play(Paths.sound(done ? 'confirmMenu' : 'scrollMenu'));
		prevRating = n;
		var sn = Std.string(n);
		var i = clearnumGrp.members.length;
		while (clearnumGrp.members.length < sn.length) {
			var num:FlxSprite = new FlxSprite(i * -68);
			num.frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumberRight');
			for (i in 0...10) num.animation.addByPrefix(Std.string(i), 'number ' + i, 24, false);
			num.animation.play('0');
			clearnumGrp.add(num);
			i ++;
		}
		i = sn.length - 1;
		for (num in clearnumGrp.members) {
			var n = sn.charAt(i);
			num.animation.play(n);
			i --;
			if (done) num.setColorTransform(0, 0, 0, 1, 255, 255, 255);
		}
		if (done) {
			subTimers.push(new FlxTimer().start(.4, () -> {
				for (num in clearnumGrp.members) num.setColorTransform();
			}));
			FlxTween.tween(clearnumGrp, {alpha: 0}, .5, {startDelay: .75, onComplete: () -> { inst.remove(clearnumGrp); }});
			FlxTween.tween(clearImage, {alpha: 0}, .5, {startDelay: .75, onComplete: () -> { inst.remove(clearImage); }});
		}
	}
}
function spawnBf(inst) {
	if (resultsBf == null) return;
	
	resultsBf.alpha = 1;
	if (resultsBf.anim == null) {
		if (resultsBf.animation == null) return;
		resultsBf.animation.play('start', true);
		subTimers.push(new FlxTimer().start(.9166, () -> { //gf appear
			if (resultsGf == null) return;
			resultsGf.animation.play('start', true);
			resultsGf.animation.finishCallback = () -> if (resultsGf != null) resultsGf.animation.play('loop');
			resultsGf.alpha = 1;
		}));
	} else {
		resultsBf.anim.play('', true);
		resultsBf.anim.play('intro', true);
		if (resultsGf != null && resultsGf.anim != null) {
			subTimers.push(new FlxTimer().start(6 / 24, () -> { //gf appear
				if (resultsGf == null) return;
				resultsGf.anim.play('');
				resultsGf.alpha = 1;
			}));
		}
		if (heartsPerfect != null) {
			inst.insert(inst.members.indexOf(resultsBf) + 1, heartsPerfect);
			subTimers.push(new FlxTimer().start(106 / 24, () -> {
				if (heartsPerfect == null) return;
				heartsPerfect.anim.play('');
				heartsPerfect.alpha = 1;
			}));
		}
	}
}
function getRank(percent) {
	if (percent >= 100) return 'PERFECT';
	if (percent >= 90) return 'EXCELLENT';
	if (percent >= 80) return 'GREAT';
	if (percent >= 60) return 'GOOD';
	return 'SHIT';
}
function resultsScreen(inst) {
	inResults = true;
	resultsActive = true;
	game.playbackRate = 1;
	game.camHUD.visible = true;
	game.camHUD.alpha = 1;
	for (grp in [game.noteGroup, game.uiGroup]) {
		game.remove(grp);
	}
	
	var newHi:Bool = false;
	var percent:Float = game.ratingPercent;
	if (Math.isNaN(percent)) percent = 0;
	
	if (PlayState.isStoryMode) {
		newHi = (PlayState.campaignScore > Highscore.getWeekScore(WeekData.getWeekFileName(), PlayState.storyDifficulty));
		StoryMenuState.weekCompleted.set(WeekData.weeksList[PlayState.storyWeek], true);
		Highscore.saveWeekScore(WeekData.getWeekFileName(), PlayState.campaignScore, PlayState.storyDifficulty);
		FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
		FlxG.save.flush();
	} else newHi = (game.songScore > Highscore.getScore(PlayState.SONG.song, PlayState.storyDifficulty));
	Highscore.saveScore(PlayState.SONG.song, game.songScore, PlayState.storyDifficulty, percent); //save hiscore shit
	
	if (game.vocals != null) game.vocals.volume = 0;
	if (game.opponentVocals != null) game.opponentVocals.volume = 0;
	
	subTimers = [];
	tallies = [];
	currentTally = -1;
	bg = new FlxSprite().makeGraphic(1, 1, -1);
	bg.color = 0xfffec85c;
	bg.scale.set(FlxG.width, FlxG.height);
	bg.updateHitbox();
	var bgFlash:FlxSprite = FlxGradient.createGradientFlxSprite(1, FlxG.height, [0xfffff1a6, 0xfffff1be], 90);
	bgFlash.scale.set(1280, 1);
	bgFlash.updateHitbox();
	bgFlash.scrollFactor.set();
	var bgTop:FlxSprite = new FlxSprite().makeGraphic(1, 1, -1);
	bgTop.color = 0xfffec85c;
	bgTop.scale.set(535, FlxG.height);
	bgTop.updateHitbox();
	var cats:FlxSprite = new FlxSprite(-135, 135); //(short for categories (or not, if you so desire))
	cats.frames = Paths.getSparrowAtlas('resultScreen/ratingsPopin');
	cats.animation.addByPrefix('main', 'Categories', 24, false);
	cats.antialiasing = ClientPrefs.data.antialiasing;
	var score:FlxSprite = new FlxSprite(-180, FlxG.height - 205);
	score.frames = Paths.getSparrowAtlas('resultScreen/scorePopin');
	score.animation.addByPrefix('main', 'tally score', 24, false);
	score.antialiasing = ClientPrefs.data.antialiasing;
	
	var totalMisses:Int = PlayState.isStoryMode ? PlayState.campaignMisses : game.songMisses;
	var successHits:Int = game.ratingsData[0].hits + game.ratingsData[1].hits;
	var comboBreaks:Int = game.ratingsData[2].hits + game.ratingsData[3].hits + totalMisses;
	
	var clearStatus:Int = Math.floor(successHits / Math.max(successHits + comboBreaks, 1) * 100);
	var rank:String = getRank(clearStatus);
	
	var bf = null;
	var gf = null;
	switch (rank) {
		case 'PERFECT':
			bf = new FlxAnimate(1342, 370);
			Paths.loadAnimateAtlas(bf, 'resultScreen/results-bf/resultsPERFECT');
			bf.anim.onComplete = () -> {
				if (bf != null) {
					bf.anim.curFrame = 137;
					bf.anim.play();
				}
			};
			heartsPerfect = new FlxAnimate(1342, 370);
			Paths.loadAnimateAtlas(heartsPerfect, 'resultScreen/results-bf/resultsPERFECT/hearts');
			heartsPerfect.anim.onComplete = () -> {
				heartsPerfect.anim.curFrame = 43;
				heartsPerfect.anim.play();
			}
			heartsPerfect.antialiasing = ClientPrefs.data.antialiasing;
			heartsPerfect.scrollFactor.set();
			heartsPerfect.alpha = .0001;
		case 'EXCELLENT':
			bf = new FlxAnimate(1329, 429);
			Paths.loadAnimateAtlas(bf, 'resultScreen/results-bf/resultsEXCELLENT');
			bf.anim.onComplete = () -> {
				if (bf != null) {
					bf.anim.curFrame = 28;
					bf.anim.play();
				}
			};
		case 'GREAT':
			bf = new FlxAnimate(929, 363);
			Paths.loadAnimateAtlas(bf, 'resultScreen/results-bf/resultsGREAT/bf');
			bf.scale.set(.93, .93);
			bf.anim.onComplete = () -> {
				if (bf != null) {
					bf.anim.curFrame = 15;
					bf.anim.play();
				}
			};
			
			gf = new FlxAnimate(802, 331);
			Paths.loadAnimateAtlas(gf, 'resultScreen/results-bf/resultsGREAT/gf');
			gf.scale.set(.93, .93);
			gf.anim.onComplete = () -> {
				if (gf != null) {
					gf.anim.curFrame = 9;
					gf.anim.play();
				}
			};
		case 'SHIT':
			bf = new FlxAnimate(0, 20);
			Paths.loadAnimateAtlas(bf, 'resultScreen/results-bf/resultsSHIT');
			bf.anim.addBySymbol('intro', 'Intro', 24, true, 0, 0);
			bf.anim.addBySymbol('loop', 'Loop Start', 24, true, 0, 0);
			bf.anim.onComplete = () -> {
				if (bf != null) {
					bf.anim.curFrame = 149; //broken...........
					bf.anim.play();
				}
			};
		default:
			bf = new FlxSprite(640, -200);
			bf.frames = Paths.getSparrowAtlas('resultScreen/resultBoyfriendGOOD');
			bf.animation.addByPrefix('start', 'Boyfriend Good Anim', 24, false);
			bf.animation.addByIndices('loop', 'Boyfriend Good Anim', [70, 71, 72, 73], '', 24, true);
			bf.antialiasing = ClientPrefs.data.antialiasing;
			bf.animation.finishCallback = () -> if (bf != null) bf.animation.play('loop');
			
			gf = new FlxSprite(625, 325);
			gf.frames = Paths.getSparrowAtlas('resultScreen/resultGirlfriendGOOD');
			gf.animation.addByPrefix('start', 'Girlfriend Good Anim', 24, false);
			gf.animation.addByIndices('loop', 'Girlfriend Good Anim', [46, 47, 48, 49, 50, 51], '', 24, true);
			gf.animation.play('start');
	}
	if (bf != null) {
		bf.scrollFactor.set();
		bf.antialiasing = ClientPrefs.data.antialiasing;
		bf.alpha = .0001;
		resultsBf = bf;
	}
	if (gf != null) {
		gf.scrollFactor.set();
		gf.antialiasing = ClientPrefs.data.antialiasing;
		gf.alpha = .0001;
		resultsGf = gf;
	}
	
	var resultsTitle:FlxSprite = new FlxSprite(0, -10);
	resultsTitle.antialiasing = ClientPrefs.data.antialiasing;
	resultsTitle.frames = Paths.getSparrowAtlas('resultScreen/results');
	resultsTitle.animation.addByPrefix('anim', 'results instance 1', 24, false);
	resultsTitle.screenCenter(0x01);
	resultsTitle.x -= 275;
	soundSystem = new FlxSprite(-15, -180);
	soundSystem.antialiasing = ClientPrefs.data.antialiasing;
	soundSystem.frames = Paths.getSparrowAtlas('resultScreen/soundSystem');
	soundSystem.animation.addByPrefix('anim', 'sound system', 24, false);
	var hiscore:FlxSprite = new FlxSprite(44, 557);//310, 570);
	hiscore.antialiasing = ClientPrefs.data.antialiasing;
	hiscore.frames = Paths.getSparrowAtlas('resultScreen/highscoreNew');
	hiscore.animation.addByPrefix('anim', 'highscoreAnim0', 24, false);
	hiscore.setGraphicSize(hiscore.width * .8);
	hiscore.updateHitbox();
	var resultsBar:FlxSprite = new FlxSprite().loadGraphic(Paths.image('resultScreen/topBarBlack'));
	resultsBar.y -= resultsBar.height;
	resultsBar.antialiasing = ClientPrefs.data.antialiasing;
	
	//var b:FlxBitmapText = new FlxBitmapText(null, null, null, FlxBitmapFont.fromMonospace(Paths.image('resultScreen/alphabet'), characters, new FlxBasePoint(49, 62)));
	//b.text = 'ABCDefgh';
	
	bg.camera = game.camHUD;
	bg.scrollFactor.set();
	inst.add(bg);
	inst.add(bgFlash);
	bgFlash.alpha = 0.0001;
	bgFlash.camera = game.camHUD;
	
	var artist:String = PlayState.SONG.artist == null ? '' : (' by ' + PlayState.SONG.artist);
	var songText:String = PlayState.isStoryMode ? WeekData.getCurrentWeek().storyName.toUpperCase() : (PlayState.SONG.song + artist);
	var rm = Math.sin(-4.4 / 180 * Math.PI);
	
	grpInfoTexts = new FlxTypedSpriteGroup();
	grpInfoTexts.setPosition(555, 187 - 75);//87
	grpInfoTexts.alpha = .0001;
	grpInfoTexts.scrollFactor.set();
	grpInfoTexts.camera = game.camHUD;
	
	var difficulty:String = Difficulty.getString();
	var diffImg = Paths.image('resultScreen/diff_' + difficulty.toLowerCase());
	if (diffImg == null) diffImg = Paths.image('resultScreen/diff_unknown');
	var diffText:FlxSprite = new FlxSprite().loadGraphic(diffImg);
	diffText.antialiasing = ClientPrefs.data.antialiasing;
	diffText.y -= diffText.height;
	grpInfoTexts.add(diffText);
	createAlphabet(grpInfoTexts, diffText.width + 135 + 22, -65 + (diffText.width + 135) * rm, songText);
	var infoClearPercent = createRatingNums(grpInfoTexts, diffText.width + 22 + 73, -72 + (diffText.width + 50) * rm + 10, clearStatus);
	infoClearPercent.visible = false;
	//bgTop.scrollFactor.set();
	//inst.add(bgTop);
	
	/*var bgCam = new FlxCamera();
	bgCam.bgColor = 0;
	FlxG.game.addChildAt(bgCam.flashSprite, FlxG.game.getChildIndex(game.camHUD.flashSprite) - 1);
	FlxG.cameras.list.insert(FlxG.cameras.list.indexOf(game.camHUD) - 1, bgCam);*/
	
	scrollHA = new FlxTypedSpriteGroup();
	scrollHA.scrollFactor.set();
	scrollHA.camera = game.camHUD;
	scrollHB = new FlxTypedSpriteGroup();
	scrollHB.scrollFactor.set();
	scrollHB.camera = game.camHUD;
	var rrank = (rank == 'SHIT' ? 'LOSS' : rank);
	var rankImage = Paths.image('resultScreen/rankText/rankScroll' + rrank);
	if (rankImage != null) {
		var ang:Float = -3.666;
		var ww = rankImage.width;
		var rad = (ang / 180 * Math.PI);
		scrollRad = rad;
		scrollWidth = ww;
		for (yy in 0...10) {
			for (xx in 0...(Math.ceil(FlxG.width / ww) + 2)) {
				var xa:Float = (xx - 1) * ww - 2 * yy + (yy % 2 == 0 ? 0 : ww);
				var ya:Float = 67.4 * yy;
				var scroll = new FlxSprite(Math.cos(rad) * xa - Math.sin(rad) * ya, 135 + Math.sin(rad) * xa + Math.cos(rad) * ya).loadGraphic(rankImage);
				scroll.y += -scroll.height + 55;
				scroll.angle = ang;
				if (yy % 2 == 0) scrollHA.add(scroll);
				else scrollHB.add(scroll);
			}
		}
	}
	var rankImageB = Paths.image('resultScreen/rankText/rankText' + rrank);
	scrollV = new FlxBackdrop(rankImageB, 0x10, 0, 30);
	scrollV.x = FlxG.width - 45;
	scrollV.scrollFactor.set();
	scrollV.camera = game.camHUD;
	
	clearImage = new FlxSprite(900 - 75, 400 - 75).loadGraphic(Paths.image('resultScreen/clearPercent/clearPercentText'));
	clearImage.scrollFactor.set();
	clearImage.camera = game.camHUD;
	clearnumGrp = new FlxTypedSpriteGroup(965 - 75, 475 - 75);
	clearnumGrp.scrollFactor.set();
	clearnumGrp.camera = game.camHUD;
	
	for (i in [resultsGf, resultsBf, heartsPerfect, grpInfoTexts, soundSystem, resultsBar, cats, score, hiscore, resultsTitle]) {
		if (i == null) continue;
		i.camera = game.camHUD;
		i.scrollFactor.set();
		i.alpha = .0001;
		inst.add(i);
	}
	
	createTally(inst, 375, 150, -1, totalHits); //i think its the total amount of notes you hit actually??
	createTally(inst, 375, 200, -1, maxCombo);
	createTally(inst, 230, 277, 0xff89e59e, game.ratingsData[0].hits);
	createTally(inst, 210, 330, 0xff89c9e5, game.ratingsData[1].hits);
	createTally(inst, 190, 385, 0xffe6cf8a, game.ratingsData[2].hits);
	createTally(inst, 220, 439, 0xffe68c8a, game.ratingsData[3].hits);
	createTally(inst, 260, 493, 0xffc68ae6, totalMisses);
	
	var scoreNames:Array = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
	var scores:Array = Std.string(Math.max(PlayState.isStoryMode ? campaignScore : game.songScore, 0)).split('');
	var scoreNums:Array = [];
	while (scores.length < 10) scores.unshift('');
	var i = 0;
	for (n in scores) {
		var num = new FlxSprite(i * 65 + 70, FlxG.height - 110);
		num.antialiasing = ClientPrefs.data.antialiasing;
		num.frames = Paths.getSparrowAtlas('resultScreen/score-digital-numbers');
		for (i in 0...10) num.animation.addByPrefix(Std.string(i), scoreNames[i], 24, false);
		num.animation.addByPrefix('disabled', 'DISABLED', 24, false);
		num.animation.addByPrefix('gone', 'GONE', 24, false);
		num.animation.play(n == '' ? 'disabled' : Std.string(n));
		num.alpha = .0001;
		num.scrollFactor.set();
		num.camera = game.camHUD;
		scoreNums.push(num);
		inst.add(num);
		i ++;
	}
	
	FlxG.sound.music.stop();
	resultsMusic = Paths.music('results' + rank);
	if (resultsMusic == null) resultsMusic = Paths.music('resultsNORMAL');
	var resultsIntro = Paths.music('results' + rank + '-intro');
	
	var delayData = rankDelay.get(rank);
	if (delayData == null) delayData = {music: 3.5, bf: 3.5, flash: 3.5, hi: 3.5};
	subTimers.push(new FlxTimer().start(delayData.bf, () -> { //bf delay
		spawnBf(inst);
		infoClearPercent.visible = true;
		var i:Int = 0;
		for (item in infoClearPercent.members) {
			if (i > 0) item.setColorTransform(0, 0, 0, 1, 255, 255, 255); //the % doesnt get colored
			i ++;
		}
		subTimers.push(new FlxTimer().start(.4, () -> {
			for (item in infoClearPercent.members) item.setColorTransform();
		}));
		subTimers.push(new FlxTimer().start(2.5, moveAlphabets));
	}));
	subTimers.push(new FlxTimer().start(delayData.flash, () -> {
		bgFlash.alpha = 1;
		FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
		inst.insert(inst.members.indexOf(bg) + 1, scrollHA);
		inst.insert(inst.members.indexOf(bg) + 1, scrollHB);
		inst.insert(inst.members.indexOf(resultsBf) + 1, scrollV);
		FlxFlicker.flicker(scrollV, 2 / 24 * 3, 2 / 24, true);
		
		var speed:Float = 7;
		scrollHA.velocity.set(Math.cos(scrollRad) * speed, Math.sin(scrollRad) * speed);
		scrollHB.velocity.set(-scrollHA.velocity.x, -scrollHA.velocity.y);
		subTimers.push(new FlxTimer().start(30 / 24, () -> { scrollV.velocity.y = -80; }));
	}));
	subTimers.push(new FlxTimer().start(delayData.music, () -> {
		if (resultsIntro == null) FlxG.sound.playMusic(resultsMusic);
		else {
			introSound = new FlxSound().loadEmbedded(resultsIntro);
			introSound.play();
			introSound.onComplete = () -> { FlxG.sound.playMusic(resultsMusic); };
			FlxG.sound.list.add(introSound);
		}
	}));
	if (newHi) {
		subTimers.push(new FlxTimer().start(delayData.hi, () -> {
			hiscore.alpha = 1;
			hiscore.animation.play('anim', true);
			hiscore.animation.finishCallback = () -> hiscore.animation.play('anim', true, false, 16);
		}));
	}
	
	resultsBar.alpha = 1;
	FlxTween.tween(resultsBar, {y: resultsBar.y + resultsBar.height}, .4, {ease: FlxEase.quartOut, startDelay: .5});
	subTimers.push(new FlxTimer().start(6 / 24, () -> {
		resultsTitle.animation.play('anim');
		resultsTitle.alpha = 1;
	}));
	subTimers.push(new FlxTimer().start(8 / 24, () -> {
		soundSystem.animation.play('anim');
		soundSystem.alpha = 1;
	}));
	subTimers.push(new FlxTimer().start(21 / 24, () -> {
		cats.animation.play('main');
		cats.alpha = 1;
		score.animation.play('main');
		score.alpha = 1;
		var i = 0;
		for (num in scoreNums) {
			num.alpha = 1;
			if (num.animation.name == 'disabled') {
				num.animation.play('main', true);
			} else {
				var digit:Int = Std.int(num.animation.name);
				var finalDigit:Int = digit;
				var start:Bool = true;
				num.animation.play('gone');
				subTimers.push(new FlxTimer().start((i - 1) / 24, () -> {
					var duration:Float = 41 / 24;
					var interval:Float = 1 / 24;
					subTimers.push(new FlxTimer().start(interval, (t) -> {
						digit = (digit + 1) % 9;
						num.animation.play(Std.string(digit), true);
						if (t.loopsLeft <= 0) {
							FlxTween.num(0, finalDigit, 23 / 24, {ease: FlxEase.quadOut, onComplete: () -> {
								num.animation.play(Std.string(finalDigit), true);
							}}, (n) -> {
								num.animation.play(Std.string(Math.round(n)));
								num.animation.finish();
							});
						}
						if (start) start = false;
						else num.animation.finish();
					}, Std.int(duration / interval)));
				}));
			}
			i ++;
		}
	}));
	subTimers.push(new FlxTimer().start(37 / 24, () -> { //bf appear, tally
		currentTally = 0;
		for (i in [clearnumGrp, clearImage]) inst.insert(inst.members.indexOf(resultsBf), i);
		bgFlash.alpha = 1;
		FlxTween.tween(bgFlash, {alpha: 0}, 5 / 24);
		FlxTween.num(0, clearStatus, 58 / 24, {ease: FlxEase.quartOut}, (n) -> {
			updateClearNums(inst, n, clearStatus);
		});
		
		subTimers.push(new FlxTimer().start(.4, () -> {
			grpInfoTexts.alpha = 1;
			FlxTween.tween(grpInfoTexts, {y: grpInfoTexts.y + 75}, .5, {ease: FlxEase.quartOut});
		}));
	}));
	
	//stickers(inst);
}
function tallyDumb(tally, e) {
	var tallied = updateTally(tally, e * 1000, e * 4);
	if (tallied) tallyDumb(++ currentTally, e);
}
function onCustomSubstateCreate(substate) {
	if (substate == 'results') resultsScreen(CustomSubstate.instance);
}
function exitSong() {
	MusicBeatState.switchState(PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
	FlxG.sound.playMusic(Paths.music('freakyMenu'));
	PlayState.changedDifficulty = false;
	PlayState.chartingMode = false;
	game.transitioning = true;
	FlxG.camera.followLerp = 0;
	Mods.loadTopMod();
	return true;
}
function resultsClose(inst) {
	CustomSubstate.closeCustomSubstate();
	
	if (introSound != null) {
		introSound.fadeOut(.5, 0);
		introSound.onComplete = null;
	}
	grpInfoTexts = null;
	resultsBf = null;
	resultsGf = null;
	while (subTimers.length > 0) {
		var t = subTimers.shift();
		t.cancel();
		t.destroy();
	}
	
	resultsActive = false;
	game.paused = true;
	game.vocals.volume = 0;
	FlxTween.tween(FlxG.sound.music, {volume: 0}, 0.8);
	FlxTween.tween(FlxG.sound.music, {pitch: 3}, 0.1, {onComplete: () -> {
		FlxTween.tween(FlxG.sound.music, {pitch: 0.5}, 0.4);
	}});
	
	var fade:FlxSprite = new FlxSprite(FlxG.width * .5, FlxG.height * .5).makeGraphic(1, 1, 0xff000000);
	fade.scale.set(FlxG.width * 2, FlxG.height * 2);
	fade.cameras = [game.camOther];
	fade.scrollFactor.set();
	fade.alpha = 0;
	inst.add(fade);
	FlxTween.tween(fade, {alpha: 1}, .25, {ease: FlxEase.expoOut});
	FlxTween.tween(Main.fpsVar, {alpha: 0}, .25, {ease: FlxEase.sineOut, startDelay: .5});
	new FlxTimer().start(.75, () -> {
		FlxTransitionableState.skipNextTransIn = true;
		MusicBeatState.switchState(PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
	});
}
function onDestroy() {
	FlxTween.tween(Main.fpsVar, {alpha: 1}, .4, {ease: FlxEase.circInOut});
	if (shownResults) FlxG.sound.playMusic(Paths.music('freakyMenu'));
}
function resultsUpdate(inst, e) {
	if (!resultsActive) return;
	game.health = 2;
	if (scrollHA.x > Math.cos(scrollRad) * scrollWidth) {
		scrollHA.x -= Math.cos(scrollRad) * scrollWidth;
		scrollHA.y -= Math.sin(scrollRad) * scrollWidth;
	}
	if (scrollHB.x < Math.cos(scrollRad) * -scrollWidth) {
		scrollHB.x += Math.cos(scrollRad) * scrollWidth;
		scrollHB.y += Math.sin(scrollRad) * scrollWidth;
	}
	if (grpInfoTexts.x < -grpInfoTexts.width) {
		grpInfoTexts.setPosition(555, 187 - 75);
		grpInfoTexts.acceleration.set(0, 0);
		grpInfoTexts.velocity.set(0, 0);
		FlxTween.tween(grpInfoTexts, {y: grpInfoTexts.y + 75}, .5, {ease: FlxEase.quartOut});
		subTimers.push(new FlxTimer().start(1.5, moveAlphabets));
	}
	var close:Bool = inst.controls.ACCEPT || (FlxG.android != null && FlxG.android.justReleased.BACK);
	if (close) {
		if (PlayState.isStoryMode) stickers(inst);
		else resultsClose(inst);
		resultsActive = false;
	}
	tallyDumb(currentTally, e);
}
function onUpdatePost(e) {
	if (inResults) {
		resultsUpdate(game, e);
		game.camGame.zoom = 1; //lol im lazy
	}
	return;
}
function createTally(inst, x, y, color, score) {
	var grp = new FlxTypedSpriteGroup(x, y);
	grp.camera = game.camHUD;
	grp.scrollFactor.set();
	grp.color = color;
	inst.add(grp);
	tallies.push({first: false, tally: 0, score: Std.int(score), wait: 0, group: grp});
}
function updateTally(index, count, time) {
	var tally = tallies[index];
	if (tally == null || tally.group == null) return false;
	tally.wait += time;
	if (tally.tally < tally.score || !tally.first) {
		tally.first = true;
		tally.tally = Math.min(tally.score * tally.wait, tally.score);
		var count:String = Std.string(Math.floor(tally.tally));
		
		var tallyGrp = tally.group;
		var i = tallyGrp.members.length;
		while (tallyGrp.members.length < count.length) {
			var num:FlxSprite = new FlxSprite(i * 43, 0);
			num.color = tallyGrp.color; //cant tint group
			num.frames = Paths.getSparrowAtlas('resultScreen/tallieNumber');
			for (n in 0...10) num.animation.addByPrefix(Std.string(n), n + ' small', 24, false);
			num.antialiasing = ClientPrefs.data.antialiasing;
			tallyGrp.add(num);
			i ++;
		}
		var i = 0;
		for (num in tallyGrp.members) {
			num.animation.play(count.charAt(i), true);
			i ++;
		}
	}
	return (tally.wait >= 1);
}
function createAlphabet(group, x, y, text) {
	var letters:Array = text.split('');
	var i:Int = 0;
	var dist:Int = 34;
	var angle:Int = -4.4;
	var angleRad:Float = angle / 180 * Math.PI;
	for (c in letters) {
		var char = characters.indexOf(c);
		if (char >= 0) {
			var letter:FlxSprite = new FlxSprite(x + i * Math.cos(angleRad) * dist, y + i * Math.sin(angleRad) * dist).loadGraphic(Paths.image('resultScreen/alphabet'), true, 392 / 8, 496 / 8);
			letter.y -= Math.cos(angle) * letter.height;
			letter.antialiasing = ClientPrefs.data.antialiasing;
			letter.animation.add('letter', [char], 24, true);
			letter.animation.play('letter');
			letter.angle = angle;
			group.add(letter);
		}
		i ++;
	}
}
function createRatingNums(group, x, y, rating) {
	var clearPercentSmall:FlxTypedSpriteGroup = new FlxTypedSpriteGroup();
	var text = rating + '%';
	var chars:Array = text.split('');
	chars.reverse();
	var i:Int = 0;
	for (char in chars) {
		var sprite:FlxSprite = new FlxSprite(x - i * 32, y + i * 4);
		if (char == '%') {
			sprite.loadGraphic(Paths.image('resultScreen/clearPercent/clearPercentTextSmall'));
			sprite.offset.y = -20;
			sprite.offset.x = -5;
		} else {
			sprite.frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumberSmall');
			sprite.animation.addByPrefix('sprite', 'number ' + char, 24, true);
			sprite.offset.y = -12;
			sprite.offset.x = -5;
			sprite.animation.play('sprite');
		}
		//sprite.y -= sprite.height;
		clearPercentSmall.add(sprite);
		sprite.antialiasing = ClientPrefs.data.antialiasing;
		i ++;
	}
	group.add(clearPercentSmall);
	return clearPercentSmall;
}
function moveAlphabets() { //move alphabet and stuff
	var rm = Math.sin(-4.4 / 180 * Math.PI);
	grpInfoTexts.velocity.x = -100;
	grpInfoTexts.velocity.y = Math.abs(100 * rm);
}
function inArray(array, pos) { //array access lags workaround???
	if (pos >= array.length) return null;
    var i = 0;
    for (item in array) {
        if (i == pos) return item;
        i ++;
    }
    return null;
}
function setArray(array, pos, v) { //this is fucking stupid..
	if (pos < 0 || pos >= array.length) return null;
	var readd:Array = [];
	while (array.length > pos) {
		var i = array.pop();
		readd.unshift(i);
	}
	readd.shift();
	readd.unshift(v);
	while (readd.length > 0) array.push(readd.shift());
}
