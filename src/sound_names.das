module sound_names

require files
require app

enum SoundName
    ACHTUNG =                0
    DOGBARK =                2
    OPENDOORSND =            3
    CLOSEDOORSND =           8
    ATKMACHINEGUNSND =       11
    ATKPISTOLSND =           12
    ATKGATLINGSND =          13
	SCHUTZADSND =            14
	GUTENTAGSND =            16
	MUTTISND =               18
	BOSSFIRESND =            20                 // note: this sound keeps going, even though its 4096 bytes long
	SSFIRESND =              23
    DEATHSCREAM1SND =        25
    DEATHSCREAM2SND =        26
    DEATHSCREAM3SND =        27
    TAKEDAMAGESND =          28
    PUSHWALLSND =            35         // test this?
    AHHHGSND =               36
    DIESND =                 38
    EVASND =                 41
    LEBENSND =               45
    NAZIFIRESND =            47
    SLURPIESND =             50
    TOT_HUNDSND =            53
    MEINGOTTSND =            55
    SCHABBSHASND =           62
    HITLERHASND =            66
    SPIONSND =               70
    NEINSOVASSND =           72
    DOGATTACKSND =           75
    LEVELDONESND =           77
    MECHSTEPSND =            79
    YEAHSND =                81
    SCHEISTSND =             83
    DEATHSCREAM4SND =        85
    DEATHSCREAM5SND =        87
    DONNERSND =              89                     // EPISODE 4 BOSS DIE
    EINESND =                92                     // EPISODE 4 BOSS SIGHTING
    ERLAUBENSND =            97                     // EPISODE 6 BOSS SIGHTING
    DEATHSCREAM6SND =        103                    // FART
    FART =                   103
    DEATHSCREAM7SND =        104                    // GASP
    DEATHSCREAM8SND =        106                    // GUH-BOY
	DEATHSCREAM9SND =        108                    // AH GEEZ!
    KEINSND =                110                    // EPISODE 5 BOSS SIGHTING
    MEINSND =                113                    // EPISODE 6 BOSS DIE
    ROSESND =                116                    // EPISODE 5 BOSS DIE

enum AudioName
    HITWALLSND              // 0
    SELECTWPNSND            // 1
    SELECTITEMSND           // 2
    HEARTBEATSND            // 3
    MOVEGUN2SND             // 4
    MOVEGUN1SND             // 5
    NOWAYSND                // 6
    NAZIHITPLAYERSND        // 7
    SCHABBSTHROWSND         // 8
    PLAYERDEATHSND          // 9
    DOGDEATHSND             // 10
    ATKGATLINGSND           // 11
    GETKEYSND               // 12
    NOITEMSND               // 13
    WALK1SND                // 14
    WALK2SND                // 15
    TAKEDAMAGESND           // 16
    GAMEOVERSND             // 17
    OPENDOORSND             // 18
    CLOSEDOORSND            // 19
    DONOTHINGSND            // 20
    HALTSND                 // 21
    DEATHSCREAM2SND         // 22
    ATKKNIFESND             // 23
    ATKPISTOLSND            // 24
    DEATHSCREAM3SND         // 25
    ATKMACHINEGUNSND        // 26
    HITENEMYSND             // 27
    SHOOTDOORSND            // 28
    DEATHSCREAM1SND         // 29
    GETMACHINESND           // 30
    GETAMMOSND              // 31
    SHOOTSND                // 32
    HEALTH1SND              // 33
    HEALTH2SND              // 34
    BONUS1SND               // 35
    BONUS2SND               // 36
    BONUS3SND               // 37
    GETGATLINGSND           // 38
    ESCPRESSEDSND           // 39
    LEVELDONESND            // 40
    DOGBARKSND              // 41
    ENDBONUS1SND            // 42
    ENDBONUS2SND            // 43
    BONUS1UPSND             // 44
    BONUS4SND               // 45
    PUSHWALLSND             // 46
    NOBONUSSND              // 47
    PERCENT100SND           // 48
    BOSSACTIVESND           // 49
    MUTTISND                // 50
    SCHUTZADSND             // 51
    AHHHGSND                // 52
    DIESND                  // 53
    EVASND                  // 54
    GUTENTAGSND             // 55
    LEBENSND                // 56
    SCHEISTSND              // 57
    NAZIFIRESND             // 58
    BOSSFIRESND             // 59
    SSFIRESND               // 60
    SLURPIESND              // 61
    TOT_HUNDSND             // 62
    MEINGOTTSND             // 63
    SCHABBSHASND            // 64
    HITLERHASND             // 65
    SPIONSND                // 66
    NEINSOVASSND            // 67
    DOGATTACKSND            // 68
    FLAMETHROWERSND         // 69
    MECHSTEPSND             // 70
    GOOBSSND                // 71
    YEAHSND                 // 72
    DEATHSCREAM4SND         // 73
    DEATHSCREAM5SND         // 74
    DEATHSCREAM6SND         // 75
    DEATHSCREAM7SND         // 76
    DEATHSCREAM8SND         // 77
    DEATHSCREAM9SND         // 78
    DONNERSND               // 79
    EINESND                 // 80
    ERLAUBENSND             // 81
    KEINSND                 // 82
    MEINSND                 // 83
    ROSESND                 // 84
    MISSILEFIRESND          // 85
    MISSILEHITSND           // 86

def get_sound_data ( name:SoundName; max_seq:int=INT_MAX )
    var index = int(name)
    var data : array<float>
    while index < length(Sounds)
        let next = Sounds[index].data |> length
        let cur = data |> length
        data |> reserve ( data|>length + next )
        for i in Sounds[index].data
            data |> push(float(i)/128.0-1.0)
        if next != 4096
            break
        index ++
    return <- data

def get_audio_data ( name:AudioName )
    var index = int(name)
    var data : array<float>
    data |> reserve ( Audio[index].data |> length )
    for i in Audio[index].data
        data |> push(float(i)/128.0-1.0)
    return <- data

def play_game_sound_2d ( name:SoundName; xy:float2; r:float; rate:int=SOUND_SAMPLE_RATE )
    play_app_sound_2d(xy, r, get_sound_data(name), rate)

def play_game_sound ( name:SoundName; rate:int=SOUND_SAMPLE_RATE )
    play_app_sound(get_sound_data(name), rate)

def play_game_audio_2d ( name:AudioName; xy:float2; r:float; rate:int=SOUND_SAMPLE_RATE )
    play_app_sound_2d(xy, r, get_audio_data(name), rate)

def play_game_audio ( name:AudioName; rate:int=SOUND_SAMPLE_RATE )
    play_app_sound(get_audio_data(name), rate)
