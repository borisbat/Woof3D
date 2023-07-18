# Woof3D

The intent here is to have 100% 'safe' version of the classic game demo,
while stressing the performance of the interpreter.

I'm using OPL3 emulator to play Adlib sounds and music. Music is in fact decoded 'on the fly' and than given to dasAudio.

The only exception is span rasterizer. With real interpreted version it goes up to about 20-30 msec from the native 2-3.

How to integrate:

1. require woof3d
2. derive from woof3d::Application and implement abstract methods and controls
3. call woof3d_main(yourApplicationInstance) on initialization
4. def woof3d_update(dt,backbuffer) on update\render

main.das has example of the standalone OpenGL\GLFW\dasSound integration.
extract.das can extract resources which we can get from .WL6 files.

note: we render column-major, not your typical row-major. host application should rotate the texture.

TODO: in no particular order

* move "fio" into application
* projectiles
* the rest of the bosses (only hans gesse works so far)
* something new to the game - current idea is to implement particles for blood, bullet shots
* sounds for hitting surfaces
* finish level screen - give LifeUp's there
* high-score table
* UI
* add links to all the sources i was looking at, while developing the demo
* music

Things I've been looking at:

https://github.com/id-Software/wolf3d
https://github.com/vpoupet/wolfenstein

Music:

http://www.vgmpf.com/Wiki/index.php/Wolfenstein_3D_(DOS)





