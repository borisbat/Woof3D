options persistent_heap

// require llvm/llvm_jit

require app
require files
require game
require engine
require sound_names

require math

[export]
def main
    InitFiles()
    setupLevel(0)
    levelFade = 0.
    dLevelFade = LEVEL_FADE_FACTOR
    play_game_sound(SoundName FART)
    raster_app_main <| $ ( dt, backbuffer )
        updateGame(dt)
        draw(level, backbuffer)
        set_app_sound_position(player.pos, player.dir)



