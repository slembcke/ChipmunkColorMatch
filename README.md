Chipmunk Color Match.
=

![Screenshot](http://files.slembcke.net/upshot/upshot_MPnWQyPZ.png)

This is a set of 4 example projects for a simple Chipmunk based color matching game. There are Chipmunk and Chipmunk Pro projects provided each with a Cocos2D and UIKit version. (Yes, UIKit works fine for simple games. The code is actually a little shorter even.)

The game rules are a simplified version of our own Crayon Ball game. The idea is to get four like colored balls to touch, causing them to pop. This version has no real win/lose conditions, scoring, menus, high scores, or anything that would make it into a real game. None of that is related to Chipmunk anyway. It only implements the core gameplay elements.

The Horse Party theme was originally created for our Mac/PC game, Crayon ball, by internet comic artist Nedroid (http://nedroid.com). There were more normal looking themes I could have picked... but this one was more fun. :D

Tutorials
=
I'll be making a full tutorial for how the game is implemented shortly. Check back later if you are interested.

About Chipmunk Pro
=

Chipmunk (the C-API) is free and open source software. Chipmunk Pro (including the Objective-C binding and optimized solver) is what we've built on top of Chipmunk. Chipmunk Pro can help you save a lot of time as it plugs into the usual Objective C memory model and familiar APIs. It even works seemlessly with ARC. You can learn more here: http://chipmunk-physics.net/chipmunkPro.php