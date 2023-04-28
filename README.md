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

* figure out font file format
* move "fio" into application
* projectiles
* the rest of the bosses (only hans gesse works so far)
* something new to the game - current idea is to implement particles for blood, bullet shots
* sounds for hitting surfaces
* hinting next to secret walls
* finish level screen - give LifeUp's there
* high-score table
* add links to all the sources i was looking at, while developing the demo








