# Woof3D

The intent here is to have 100% 'safe' version of the classic game demo,
while stressing the performance of the interpreter.

How to integrate:

1. require woof3d
2. derive from woof3d::Application and implement abstract methods and controls
3. call woof3d_main(yourApplicationInstance) on initialization
4. def woof3d_update(dt,backbuffer) on update\render

main.das has example of the standalone OpenGL\GLFW\dasSound integration.
extract.das can extract resources which we can get from .WL6 files.

note: we render column-major, not your typical row-major. host application should rotate the texture.

TODO: in no particular order

1. additional health items - things like blood puddles, etc. stop going over 100hp
2. life system - and points for treasures. when run out of extra life - restart
3. redo death screen - so that we can display some text
4. projectiles (and the rest of the bosses, only hans gesse works so far)
5. something new to the game - current idea is to implement particles for blood, bullet shots
6. sounds for hitting surfaces
7. chaingun to take 2 ammo at the time. figure out max ammo






