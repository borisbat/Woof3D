module game

require files
require app
require sound_names
require entities

require daslib/algorithm
require daslib/json_boost
require daslib/random
require math
require fio

var frame_time = 0.66

let CHEAT_DISABLE_ENEMIES = false

let DEAD_BODY_REMOVE_DISTANCE = 10. // how far away from player dead bodies are removed

let SHOT_ALERT_RADIUS = 10. // how far away from player enemies are alerted by shots

let AGRO_TIME = 20. // they stay agro even if they can't see you for that many seconds

let LEVEL_FADE_TIME = 1.
let LEVEL_FADE_FACTOR = 1.0 / LEVEL_FADE_TIME / 60.

let PAIN_SOUND_RADIUS = 64.
let SHOT_SOUND_RADIUS = 64.
let AGRO_SOUND_RADIUS = 64.

let DOOR_SOUND_PLAYBACK_RATE = 18000
let DOOR_SOUND_RADIUS = 64.      // how far away door sound can be heard (in tiles)
let DOOR_OPEN_SPEED = 2.0        // how fast door opens (in tiles per second)
let DOOR_CLOSE_SPPED = 2.0       // how fast door closes (in tiles per second)
let DOOR_STAYS_CLOSED = 2.0      // how long door stays closed (in seconds)

// hud

var playerHoodTime = 0.
var playerHealth = 1.

var hudMessage = ""
var hudMessageTime = 0.

def hudText ( text:string; time:float )
    hudMessage = text
    hudMessageTime = time

def clearHud
    hudMessage = ""
    hudMessageTime = 0.

//

struct Animation
    sprites : array<int>
    spriteIndex : int
    timer : float
    loop : bool
    orientable : bool
    rate : float

def Animation ( SPRITES:array<int>; LOOP:bool=false; ORIENTABLE:bool=false; RATE:float=1.0/6.0 )
    var self : Animation
    with self
        sprites := SPRITES
        spriteIndex = 0
        timer = 0.
        loop = LOOP
        orientable = ORIENTABLE
        rate = RATE
    return <- self

enum Category
    nothing
    prop
    deadBody
    enemy

struct PlayerRelativeCoordinates
    rpos:float2
    opos:float2

struct Entity
    category : Category
    mapItem      : int
    spriteIndex  : int
    animation    : Animation?
    orientable   : bool
    pos          : float2
    dir          : float2
    prc          : PlayerRelativeCoordinates

var objects : array<Entity?>

enum EnemyCategory
    guard
    dog
    officer
    ss
    mutant
// bosses
    hansGrosse

struct EnemyClass
    enemyCategory : EnemyCategory
    spriteIndex : int
    runSprites : array<int>
    deathSprites : array<int>
    damageSprites : array<int>
    attackSprites : array<int>
    orientable : bool
// movement and location
    radius : float          // how big enemy is
    speed : float           // how fast enemy moves
// everything hp
    hp : int                // how much hp enemy has
// everything attack
    attackDamage : int      // how much damage it does on each attack
    attackFireRate : float  // how fast it attacks
    attackDistance : float  // how far away from player enemy can attack
    comfortDistance : float // how far away from player enemy stops chasing
    attackDelay : float2    // min, max
    attackSound : SoundName // sound played when enemy attacks
    agroSound : SoundName   // sound played when enemy sees player

// weaponFireRate : float[4] = [[float 2.5; 2.5; 7.1; 14.2]]

let enemyClasses <- [[EnemyClass
// guard
    hp = 25,
    radius = .25,
    speed = 0.065 * 0.35,
    attackDamage = 15,
    comfortDistance = 3.,
    attackDistance = 5.,
    attackFireRate = 2.5,
    attackDelay = float2(1., 2.),
    attackSound = SoundName ATKPISTOLSND,
    agroSound = SoundName ACHTUNG,
    spriteIndex = 50,
    runSprites <- [{auto 58; 66; 74}],
    deathSprites <- [{auto 90; 91; 92; 93; 95}],
    damageSprites <- [{auto 90; 94; 50}],
    attackSprites <- [{auto 96; 97; 98; 97; 50}];
// dog
    hp = 1,
    radius = .3,
    speed = 0.065 / 2.,
    attackDamage = 10,
    attackDistance = 1.5,
    comfortDistance = 1.5,
    attackFireRate = 3.5,
    attackDelay = float2(0.2, 0.5),
    attackSound = SoundName DOGATTACKSND,
    agroSound = SoundName DOGBARK,
    spriteIndex = 99,
    runSprites <- [{auto 107; 115; 123}],
    deathSprites <- [{auto 131; 132; 133; 134}],
    damageSprites <- [{auto 131; 99}],
    attackSprites <- [{auto 135; 136; 137; 136; 99}];
// officer
    hp = 50,
    radius = .3,
    speed = 0.065 * 0.5,
    attackDamage = 30,
    attackDistance = 7.,
    comfortDistance = 5.,
    attackFireRate = 2.5,
    attackDelay = float2(0.5, 1.),
    attackSound = SoundName ATKPISTOLSND,
    agroSound = SoundName GUTENTAGSND,
    spriteIndex = 238,
    runSprites <- [{auto 246; 254; 262}],
    deathSprites <- [{auto 279; 280; 281; 283; 284}],
    damageSprites <- [{auto 279; 282; 238}],
    attackSprites <- [{auto 285; 286; 287; 286; 238}];
// ss
    hp = 50,
    radius = .3,
    speed = 0.065 * 0.5,
    attackDamage = 45,
    attackDistance = 7.,
    comfortDistance = 3.,
    attackFireRate = 2.5,
    attackDelay = float2(0.8, 1.5),
    attackSound = SoundName SSFIRESND,
    agroSound = SoundName SCHUTZADSND,
    spriteIndex = 138,
    runSprites <- [{auto 146; 154; 162}],
    deathSprites <- [{auto 179; 180; 181; 183}],
    damageSprites <- [{auto 179; 182; 138}],
    attackSprites <- [{auto 184; 185; 186; 186; 138}];
// mutant
    hp = 45,
    radius = .4,
    speed = 0.065 * 0.35,
    attackDamage = 45,
    attackDistance = 3.,
    comfortDistance = 1.5,
    attackFireRate = 2.5,
    attackDelay = float2(1., 2.),
    attackSound = SoundName ATKGATLINGSND,
    agroSound = SoundName MUTTISND,
    spriteIndex = 187,
    runSprites <- [{auto 195; 203; 211}],
    deathSprites <- [{auto 228; 229; 230; 232; 233}],
    damageSprites <- [{auto 228; 231; 187}],
    attackSprites <- [{auto 234; 235; 236; 237; 236; 187}];
// hansGrosse
    hp = 800,
    radius = .4,
    speed = 0.065 * 0.35,
    attackDamage = 45,
    attackDistance = 10.,
    comfortDistance = 5.,
    attackFireRate = 2.5,
    attackDelay = float2(2., 3.),
    attackSound = SoundName BOSSFIRESND,
    agroSound = SoundName GUTENTAGSND,
    spriteIndex = 296,
    runSprites <- [{auto 296; 297; 298; 299}],
    deathSprites <- [{auto 304; 305; 306; 303}],
    // damageSprites <- [{auto 228; 231; 187}],
    attackSprites <- [{auto 300; 301; 302}]
]]

struct Enemy : Entity
    enemyCategory : EnemyCategory
    patrolling : bool
    health : int = 100
    attackTimer : float = 0.
    agroTimer : float = 0.
    running : bool = false
    run : float2
    radius : float

var enemies : array<Enemy?>

def startAnimation ( var entity:Entity; ANIMATION:Animation? )
    entity.animation = ANIMATION
    entity.spriteIndex = entity.animation.sprites[0]

var seed = random_seed(13)

let random_take_damage_snd = [[SoundName
    SoundName DEATHSCREAM1SND;
    SoundName DEATHSCREAM2SND;
    SoundName DEATHSCREAM3SND]]

let random_death_snd = [[SoundName
    SoundName DEATHSCREAM7SND;
    SoundName DEATHSCREAM8SND;
	SoundName DEATHSCREAM9SND]]

def takeDamage ( var self:Enemy; DAMAGE:int )
    with self
        agroTimer = AGRO_TIME   // getting shot sets up agro timer
        health -= DAMAGE
        if health <= 0
            category = Category deadBody
            self |> die()
        else
            if animation == null
                if !empty(enemyClasses[int(enemyCategory)].damageSprites)
                    self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].damageSprites,false,false))
            play_game_sound_2d(random_take_damage_snd[ random_int(seed) % 3], pos, PAIN_SOUND_RADIUS)
            self |> rotateTowardsPlayer()

def die ( var self:Enemy )
    with self
        health = -100
        orientable = false
        self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].deathSprites))
        play_game_sound_2d(random_death_snd[ random_int(seed) % 3], pos, PAIN_SOUND_RADIUS)
        if enemyCategory==EnemyCategory dog
            // self |> dropLoot(cx,cy,Collectible dogBone)
            pass
        elif enemyCategory==EnemyCategory guard
            dropLoot(pos,Collectible AmmoClip, player.ammo < 8 ? 1. : 0.25)
        elif enemyCategory==EnemyCategory officer
            dropLoot(pos,Collectible AmmoClip, player.ammo < 8 ? 1. : 0.5)
        elif enemyCategory==EnemyCategory ss
            dropLoot(pos,Collectible MachineGun, 1.)
        elif enemyCategory==EnemyCategory mutant
            dropLoot(pos,Collectible Chaingun, 1.)
        elif enemyCategory==EnemyCategory hansGrosse
            dropLoot(pos,Collectible KeyGold, 1., true)

def dropLoot ( XY : float2; loot:Collectible; chanceToDrop:float; force:bool = false ) : bool
    let drop = random_float(seed)
    if drop <= chanceToDrop
        objects |> push <| new [[Entity
            category = Category prop,
            mapItem = int(loot),
            spriteIndex = int(loot)-21,
            pos = XY                        // TODO: randomize position?
        ]]
    return true

def getPlayerRelativeCoordinates ( xy:float2 )
    let o = xy - player.pos
    return [[PlayerRelativeCoordinates
        rpos=float2(o.x * player.dir.x + o.y * player.dir.y, -o.x * player.dir.y + o.y * player.dir.x),
        opos=o
    ]]

[jit,hint(unsafe_range_check)]
def trace ( px,py,pdx,pdy,maxDist:float; writeVis:bool ) : tuple<t:float; tx:float; textureIndex:int>
    // direction of the ray
    var dx = pdx
    var dy = pdy
    // direction in which the ray moves along each axis
    let stepx = dx >= 0. ? 1 : -1
    let stepy = dy >= 0. ? 1 : -1
    // take absolute values of ray direction
    dx = float(stepx) * dx
    dy = float(stepy) * dy
    // cell position of the ray on the map (starting from the player position)
    var cx = floori(px)
    var cy = floori(py)
    // remaining fractional distance from the ray position to the next cell (0 < rfx, rfy <= 1)
    var rfx = stepx > 0 ? 1. - (px % 1.) : px % 1.
    if rfx == 0.
        rfx = 1.
        cx += stepx
    var rfy = stepy > 0 ? 1. - (py % 1.) : py % 1.
    if rfy == 0.
        rfy = 1.
        cy += stepy
    // total time traveled by the ray
    var t = 0.
    // plane0 value of the cell visited by the ray
    var m0 : int
    // coordinate on the wall tile where the ray hit (0 <= tx <= 1)
    var tx : float
    // index of tile to display
    var textureIndex : int
    // ray casting loop
    while t < maxDist
        if writeVis
            visibility_plane[OFS(cx,cy)] = true
        m0 = level.plane0[OFS(cx,cy)]
        if m0 <= 63
            // hit a wall
            var wallShift = 0.
            let m1 = level.plane1[OFS(cx,cy)]
            if m1 == 98
                // pushwall
                assume timer = timer_plane[OFS(cx,cy)]
                if timer.active
                    wallShift = timer.t
                    if timer.dx != 0
                        // wall moves horizontally
                        if dx * rfy >= dy * wallShift
                            // ray hits wall
                            let dt = wallShift / dx
                            t += dt
                            rfy -= dt * dy
                            rfx -= wallShift
                        else
                            // ray moves to next cell
                            let dt = rfy / dy
                            t += dt
                            rfy = 1.
                            cy += stepy
                            rfx -= dt * dx
                            continue
                    else
                        // wall moves vertically
                        if dy * rfx >= dx * wallShift
                            // ray hits wall
                            let dt = wallShift / dy
                            t += dt
                            rfx -= dt * dx
                            rfy -= wallShift
                        else
                            // ray moves to next cell
                            let dt = rfx / dx
                            t += dt
                            rfx = 1.
                            cx += stepx
                            rfy -= dt * dy
                            continue
            if rfx == 1. - wallShift
                // NS wall
                textureIndex = 2 * m0 - 1
                // fix texture orientation depending on ray direction
                tx = stepx * stepy > 0 ? 1. - rfy : rfy
            else
                // EW wall
                textureIndex = 2 * m0 - 2
                // fix texture orientation depending on ray direction
                tx = stepx * stepy < 0 ? 1. - rfx : rfx
            break
        elif m0 <= 101
            // hit a door
            var doorShfit = 0.
            assume timer = timer_plane[OFS(cx,cy)]
            if timer.active
                doorShfit = timer.t
            if (m0 & 1) == 0
                // NS door
                if rfx >= .5 && (rfx - .5) * dy < rfy * dx
                    // ray hits the central door line
                    let dt = (rfx - .5) / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = .5
                    tx = stepy > 0 ? 1. - rfy : rfy
                    tx -= doorShfit
                    if tx >= 0.
                        // ray hits the door
                        if m0 == 90
                            textureIndex = 99
                        elif m0 == 92
                            textureIndex = 105
                        elif m0 == 94
                            textureIndex = 105
                        elif m0 == 100
                            textureIndex = 103
                        else
                            assert(false,"we should not be here?")
                        break
                if rfx * dy >= rfy * dx
                    // hit the side wall
                    let dt = rfy / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = 1.
                    cy += stepy
                    textureIndex = 100
                    tx = stepx > 0 ? 1. - rfx : rfx
                    break
                else
                    // pass through
                    let dt = rfx / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = 1.
                    cx += stepx
                    continue
            else
                // EW door
                if rfy >= .5 && (rfy - .5) * dx < rfx * dy
                    // ray hits the central door line
                    let dt = (rfy - .5) / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = .5
                    tx = stepx > 0 ? 1. - rfx : rfx
                    tx -= doorShfit
                    if tx >= 0.
                        // ray hits the door
                        if m0 == 91
                            textureIndex = 98
                        elif m0 == 93
                            textureIndex = 104
                        elif m0 == 95
                            textureIndex = 104
                        elif m0 == 101
                            textureIndex = 102
                        else
                            assert(false,"we should not be here?")
                        break
                if rfy * dx >= rfx * dy
                    // hit the side wall
                    let dt = rfx / dx
                    t += dt
                    rfy -= dt * dy
                    rfx = 1.
                    cx += stepx
                    textureIndex = 101
                    tx = stepy > 0 ? 1. - rfy : rfy
                    break
                else
                    // pass through
                    let dt = rfy / dy
                    t += dt
                    rfx -= dt * dx
                    rfy = 1.
                    cy += stepy
                    continue
        // move to the next cell
        if rfx * dy <= rfy * dx
            // move to next cell horizontally
            let dt = rfx / dx
            t += dt
            rfx = 1.
            cx += stepx
            rfy -= dt * dy
        else
            // move to next cell vertically
            let dt = rfy / dy
            t += dt
            rfy = 1.
            cy += stepy
            rfx -= dt * dx
    return [[auto t, tx, textureIndex]]

enum WeaponType
    knife = 0
    pistol = 1
    machineGun = 2
    chainGun = 3

struct Player
    pos : float2
    dir : float2
    health : int = 100
    silverKey : bool
    goldKey : bool
    ammo : int = 8
    speed : float = 0.065
    speed_a : float = 0.05
    radius : float = 0.25
    moveForwars : bool = false
    moveBackward : bool = false
    strafeLeft : bool = false
    strafeRight : bool = false
    turnLeft : bool = false
    turnRight : bool = false
    turnAngle : float = 0.0
    weaponSprite : int = 421
    weaponAnimation : Animation?
    weaponType : WeaponType = WeaponType pistol
    hasWeapon : bool[4] = [[bool true; true; false; false ]]
    weaponSounds : SoundName[4] = [[SoundName
        SoundName ATKMACHINEGUNSND;
        SoundName ATKPISTOLSND;
        SoundName ATKMACHINEGUNSND;
        SoundName ATKGATLINGSND]]
    weaponFireRate : float[4] = [[float 2.5; 2.5; 7.1; 14.2]]
    weaponDamage : int[4] = [[int 16; 18; 18; 18]]

def switchWeapon ( var self:Player; WEAPON_TYPE:WeaponType )
    with self
        if !hasWeapon[int(WEAPON_TYPE)]
            return
        weaponType = WEAPON_TYPE
        weaponSprite = 416 + int(weaponType) * 5

def canMoveTo ( self:Player; XY:float2 )
    for enemy in enemies
        if enemy.category == Category enemy
            let dist = length(enemy.pos - XY)
            if dist < self.radius + enemy.radius
                return false
    return canMoveTo(XY,self.radius)

def canMoveTo ( XY:float2;r:float )
    let f = fract(XY)
    let i = floori(XY)
    if collision_plane[OFS(i)]
        return false
    if f.x < r
        if collision_plane[OFS(i.x-1,i.y)]
            return false
        if f.y < r && collision_plane[OFS(i.x-1,i.y-1)]
            return false
        if f.y > 1.-r && collision_plane[OFS(i.x-1,i.y+1)]
            return false
    if f.x > 1.-r
        if collision_plane[OFS(i.x+1,i.y)]
            return false
        if f.y < r && collision_plane[OFS(i.x+1,i.y-1)]
            return false
        if f.y > 1.-r && collision_plane[OFS(i.x+1,i.y+1)]
            return false
    if f.y < r && collision_plane[OFS(i.x,i.y-1)]
        return false
    if f.y > 1.-r && collision_plane[OFS(i.x,i.y+1)]
        return false
    return true

def move ( var self:Player; length,sideways:float )
    with self
        let oldxy = floori(pos)
        let XY = pos + dir*length + dir.yx*float2(-sideways,sideways)
        if self |> canMoveTo(float2(XY.x, pos.y))
            pos.x = XY.x
        if self |> canMoveTo(float2(pos.x, XY.y))
            pos.y = XY.y
        let newxy = floori(pos)
        if newxy != oldxy
            player |> collect(newxy)

let treasureAudio = [[AudioName
    AudioName BONUS1SND;
    AudioName BONUS2SND;
    AudioName BONUS3SND;
    AudioName BONUS3SND]]

def collect ( var self:Player; XY:int2 )
    with self
    // WE TRIGGER LEVEL SWITCHES HERE AFTER BOSSES
        // print("{levelIndex} {X} {Y}\n")
        if levelIndex==8 && XY.y<8
            // hans grosse level, we see the 'run away' wall around line 7
            switchLevel(levelIndex+1)
            return
    // WE GO WITH NORMAL PICKUPS
        var collected : array<int>
        for obj,index in objects,count()
            if floori(obj.pos)!=XY
                continue
            var m1 = obj.spriteIndex + 21
            if isCollectible(m1)
                var col : Collectible
                for c in each_enum(type<Collectible>)
                    if int(c)==m1
                        col = c
                        break
                if isHpRestore(m1)
                    if health < 100
                        collected |> push(index)
                        if col==Collectible DogFood
                            health += 4
                            play_game_sound(SoundName FART)
                        elif col==Collectible Food
                            play_game_audio(AudioName HEALTH1SND)
                            health += 10
                        elif col==Collectible Medkit
                            play_game_audio(AudioName HEALTH2SND)
                            health += 24
                        health = min(health, 100)
                elif col==Collectible LifeUp
                    health = 200
                    collected |> push(index)
                    play_game_audio(AudioName BONUS1UPSND)
                elif isKey(m1)
                    if col==Collectible KeySilver
                        silverKey = true
                    elif col==Collectible KeyGold
                        goldKey = true
                    collected |> push(index)
                    play_game_audio(AudioName GETKEYSND)
                elif col==Collectible AmmoClip
                    if ammo < 199
                        collected |> push(index)
                        ammo = min(199,ammo+8)
                        play_game_audio(AudioName GETAMMOSND)
                elif isTreasure(m1)
                    collected |> push(index)
                    play_game_audio(treasureAudio[m1-52])
                elif col == Collectible MachineGun || col == Collectible Chaingun
                    let wep = (col==Collectible MachineGun) ? WeaponType machineGun : WeaponType chainGun
                    if !hasWeapon[int(wep)] || ammo<199
                        collected |> push(index)
                        ammo = min(199,ammo+25)
                        if !hasWeapon[int(wep)]
                            play_game_audio((col==Collectible MachineGun) ? AudioName GETMACHINESND : AudioName GETGATLINGSND)
                            hasWeapon[int(wep)] = true
                            self |> switchWeapon(wep)
        collected |> sort
        reverse(collected)
        for i in collected
            objects |> erase(i)

def turn ( var self:Player; alpha:float )
    with self
        let sa = sin(alpha)
        let ca = cos(alpha)
        dir = normalize(float2(dir.x * ca - dir.y * sa,dir.x * sa + dir.y * ca))

def update ( var self:Player )
    with self
        if health <= 0
            if is_key_pressed(VK_SPACE) || is_key_pressed(VK_ENTER)
                switchLevel(levelIndex, true)
            return
        var changed = false
        if weaponAnimation == null
            if is_key_pressed(VK_1)
                self |> switchWeapon(WeaponType knife)
            elif is_key_pressed(VK_2)
                self |> switchWeapon(WeaponType pistol)
            elif is_key_pressed(VK_3)
                self |> switchWeapon(WeaponType machineGun)
            elif is_key_pressed(VK_4)
                self |> switchWeapon(WeaponType chainGun)
        if is_key_pressed(VK_RIGHT)
            turnAngle += 1.
        if is_key_pressed(VK_LEFT)
            turnAngle -= 1.
        if turnAngle != 0.
            self |> turn(turnAngle * speed_a * frame_time)
            turnAngle = 0.
            changed = true
        var forward = 0.
        var sideways = 0.
        if is_key_pressed(VK_UP)
            forward += speed
        if is_key_pressed(VK_DOWN)
            forward -= speed
        if is_key_pressed(VK_A)
            sideways -= speed
        if is_key_pressed(VK_D)
            sideways += speed
        if forward != 0.
            if sideways != 0.
                self |> move(frame_time * forward / sqrt(2.), frame_time * sideways / sqrt(2.))
            else
                self |> move(frame_time * forward, 0.)
            changed = true
        elif sideways != 0.
            self |> move(0., frame_time * sideways)
            changed = true
        if weaponAnimation != null
            assume a = weaponAnimation
            a.timer += weaponFireRate[int(weaponType)] / 16. * frame_time
            if a.timer >= 1.
                a.timer = 0.
                if a.spriteIndex >= a.sprites |> length - 1
                    weaponAnimation = null
                    weaponSprite = 416 + int(weaponType) * 5
                else
                    a.spriteIndex += 1
                    weaponSprite = a.sprites[a.spriteIndex]
        if is_key_pressed(VK_SPACE)
            player |> activate()
        if is_key_pressed(VK_LCONTROL) || is_key_pressed(VK_RCONTROL)
            player |> shoot()

def alert ( xy:float2; radius:float )
    for enemy in enemies
        if enemy.category == Category enemy
            if length(enemy.pos - xy) < radius
                enemy.agroTimer = AGRO_TIME

def shoot ( var self:Player )
    with self
        if weaponAnimation == null
            if weaponType!=WeaponType knife && ammo==0
                return
            if weaponType == WeaponType knife
                play_game_audio(AudioName ATKKNIFESND)
            else
                ammo --
                play_game_sound(weaponSounds[int(weaponType)])
                alert(pos,SHOT_ALERT_RADIUS)
            weaponAnimation = new Animation([{for frame in range(4); frame+416+int(weaponType)*5}])
            var d = zIndex[int(pixelWidth) / 2]
            if weaponType == WeaponType knife
                d = min(d,1.) // one meter?
            for enemy in enemies
                if enemy.category != Category enemy
                    continue
                if !visibility_plane [OFS(floori(enemy.pos))]
                    continue
                var prc = getPlayerRelativeCoordinates(enemy.pos)
                if prc.rpos.x < 0.
                    continue
                if prc.rpos.x >= d
                    continue
                if abs(prc.rpos.y) <= .3
                    *enemy |> takeDamage(weaponDamage[int(weaponType)])

def isTooCloseToDoor ( var self:Player; XY:int2 )
    with self
        if XY==floori(pos)
            return true
        let fxy = abs(float2(XY)+float2(0.5)-pos)
        let rext = radius + 0.5
        if fxy.x<=rext && fxy.y<=rext
            return true
        return false

def activate ( var self:Player )
    with self
        var XY = floori(pos)
        var DXY : int2
        if abs(dir.x) >= abs(dir.y)
            DXY.x = dir.x >= 0. ? 1 : -1
            XY.x += DXY.x
        else
            DXY.y = dir.y >= 0. ? 1 : -1
            XY.y += DXY.y
        let m0 = level.plane0[OFS(XY)]
        let m1 = level.plane1[OFS(XY)]
        if m0==21 && DXY.x!=0
            // elevator
            switchLevel(levelIndex+1)
        elif m0>=90 && m0<=101
            // door
            if (m0==92 || m0==93) && !goldKey
                // gold-locked door
                play_game_audio_2d(AudioName HALTSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS)
                hudText("GOLD KEY REQUIRED!", 2.)
                return
            if (m0==94 || m0==95) && !silverKey
                // silver-locked door
                play_game_audio_2d(AudioName HALTSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS)
                hudText("SILVER KEY REQUIRED!", 2.)
                return
            assume timer = timer_plane[OFS(XY)]
            if !timer.active
                timer = [[Timer
                    t = 0.,
                    opening = true,
                    active = true,
                    isDoor = true
                ]]
                play_game_sound_2d(SoundName OPENDOORSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS, DOOR_SOUND_PLAYBACK_RATE)
        elif m1 == 98
            // pushwall
            assume timer = timer_plane[OFS(XY)]
            if !timer.active && level.plane0[OFS(XY+DXY)] >= 106
                // there is no active timer for this wall, and it can move backwards
                timer = [[Timer
                    t = 0.,
                    dx = DXY.x,
                    dy = DXY.y,
                    steps = 2,
                    opening = true,
                    active = true,
                    isWall = true
                ]]
                play_game_sound_2d(SoundName OPENDOORSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS)
        else
            assume timer = timer_plane[OFS(XY)]
            if !timer.active
                timer = [[Timer
                    t = 0.5,
                    active = true
                ]]
                play_game_audio_2d(AudioName DONOTHINGSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS)

def clearKeys ( var self:Player )
    with self
        goldKey = false
        silverKey = false

def die ( var self:Player )
    self.health = 0
    play_game_sound(random_death_snd[ random_int(seed) % 3])

def takeDamage ( var self:Player; DAMAGE:int )
    with self
        flashScreen(float4(0.,1.,1.,1.),float4(255.,0.,0.,0.), 3. / 60.)
        health -= DAMAGE
        if health <= 0
            self |> die()
        else
            play_game_sound(random_take_damage_snd[ random_int(seed) % 3])

var player = Player()

struct Timer
    t : float
    dx, dy : int
    steps : int
    opening : bool
    active : bool
    isDoor : bool
    isWall : bool

var timer_plane : Timer[64*64]

var collision_plane : bool[64*64]

var visibility_plane : bool[64*64]

var zIndex : array<float>

var fov = 1.
var pixelWidth = 320.
var pixelHeight = 200.
var wallHeight = float(pixelWidth) / (2. * fov)

var level : Level
var levelIndex = 0
var nextLevelIndex = 0
var levelFade = 1.
var dLevelFade = 0.
var becauseOfDeath = false

var flashFactor = float4(1.,1.,1.,1.)
var flashBase = float4(0.,0.,0.,0.)
var flashTime = 0.

def switchLevel ( index:int; reasonBecauseOfDeath = false )
    clearHud()
    becauseOfDeath = reasonBecauseOfDeath
    play_game_sound(SoundName LEVELDONESND)
    levelFade = 1.
    dLevelFade = - LEVEL_FADE_FACTOR
    nextLevelIndex = index

def flashScreen ( ff,fb:float4; ft:float )
    flashFactor = ff
    flashBase = fb
    flashTime = ft

def updatePalette
    // udpate flash
    if flashTime > 0.
        flashTime -= 1./60. * frame_time
        if flashTime < 0.
            flashFactor = float4(1.,1.,1.,1.)
            flashBase = float4(0.,0.,0.,0.)
            flashTime = 0.
    if dLevelFade != 0.
        // fade between levels
        var pal : uint[256]
        if becauseOfDeath && dLevelFade < 0.
            for p,d in GamePalette, pal
                d = pack_float_to_byte ( float4(255.,0.,0.,255.0) * levelFade )
        else
            for p,d in GamePalette, pal
                d = pack_float_to_byte ( unpack_byte_to_float(p) * levelFade )
        set_palette(pal)
        levelFade += dLevelFade * frame_time
        if dLevelFade > 0. && levelFade >= 1.
            dLevelFade = 0.
            levelFade = 1.
        elif dLevelFade < 0. && levelFade <= 0.
            levelIndex = nextLevelIndex
            setupLevel(nextLevelIndex)
            levelFade = 0.
            dLevelFade = LEVEL_FADE_FACTOR
    elif player.health <= 25 || flashTime > 0.
        // health fading to red + flash
        var factor = max(0., 1. - float(player.health) / 25.)
        factor = sqrt(factor)
        let ifactor = 1. - factor
        var pal : uint[256]
        for p,d in GamePalette,pal
            let fc = unpack_byte_to_float(p) * flashFactor + flashBase
            let tc = float4(255.,fc.y*ifactor,fc.z*ifactor,fc.w)
            let rc = lerp(fc, tc, float4(factor))
            d = pack_float_to_byte ( clamp(rc, float4(0.), float4(255.)) )
        set_palette(pal)
    else
        set_palette(GamePalette)

def setupLevel ( index:int )
    to_log(LOG_INFO, "LOADING LEVEL {index}\n}")
    level := Levels[index]
    delete objects
    delete enemies
    for b in collision_plane
        b = false
    for t in timer_plane
        t.active = false
    if becauseOfDeath
        player = Player()
    else
        player |> clearKeys()
    for y in range(64)
        for x in range(64)
            // structual
            let m0 = level.plane0[OFS(x,y)]
            if m0 <= 63
                // wall
                collision_plane[OFS(x,y)] = true
            elif 90 <= m0 && m0 <= 101
                // door
                collision_plane[OFS(x,y)] = true
            // entities
            let m1 = level.plane1[OFS(x,y)]
            if isPlayer(m1)
                // player
                player.pos = float2(x,y) + float2(0.5)
                getPlayerDirection(m1-19,player.dir.x,player.dir.y)
            elif isProp(m1)
                objects |> push <| new [[Entity
                    category = Category prop,
                    mapItem = m1,
                    spriteIndex = m1-21,
                    pos = float2(x,y) + float2(0.5)
                ]]
                if isBlocking(m1)
                    collision_plane[OFS(x,y)] = true
            elif isPushWall(m1)
                pass
                // pushwall
                // score.totalSecrets ++
            elif isDeadGuard(m1)
                // dead guard
                objects |> push <| new [[Entity
                    category = Category prop,
                    mapItem = 95 - 21,
                    spriteIndex = 95,
                    pos = float2(x,y) + float2(0.5)
                ]]
            elif !CHEAT_DISABLE_ENEMIES && isEnemy(m1)   // disabled enemies for now
                var category : EnemyCategory
                var patrolling = false
                var orientable = true
                var ex = x
                var ey = y
                if isStandingGuard(m1)
                    category = EnemyCategory guard
                elif isPatrollingGuard(m1)
                    category = EnemyCategory guard
                    patrolling = true
                elif isStandingDog(m1)
                    category = EnemyCategory dog
                elif isPatrollingDog(m1)
                    category = EnemyCategory dog
                    patrolling = true
                elif isStandingSS(m1)
                    category = EnemyCategory ss
                elif isPatrollingSS(m1)
                    category = EnemyCategory ss
                    patrolling = true
                elif isStandingMutant(m1)
                    category = EnemyCategory mutant
                elif isPatrollingMutant(m1)
                    category = EnemyCategory mutant
                    patrolling = true
                elif isFakeHitler(m1)
                    print("FAKE HITLER AT {x},{y}\n")
                elif isHitler(m1)
                    print("HITLER AT {x},{y}\n")
                elif isGeneralFettgesicht(m1)
                    print("GENERAL FETTGESICHT AT {x},{y}\n")
                elif isDoctorSchabbs(m1)
                    print("DOCTOR SCHABBS AT {x},{y}\n")
                elif isGretelGrosse(m1)
                    print("GRETEL GROSSE AT {x},{y}\n")
                elif isHansGrosse(m1)
                    print("HANS GROSSE AT {x},{y}\n")
                    category = EnemyCategory hansGrosse
                    orientable = false
                    // ey = 30
                elif isOttoGiftmacher(m1)
                    print("OTTO GIFTMACHER AT {x},{y}\n")
                elif isRedPacManGhost(m1)
                    print("RED PACMAN GHOST AT {x},{y}\n")
                elif isPinkPacManGhost(m1)
                    print("PINK PACMAN GHOST AT {x},{y}\n")
                elif isOrangePacManGhost(m1)
                    print("ORANGE PACMAN GHOST AT {x},{y}\n")
                elif isBluePacManGhost(m1)
                    print("BLUE PACMAN GHOST AT {x},{y}\n")
                else
                    print("UNKNOWN ENEMY AT {x},{y}\n")
                    // to_log(LOG_INFO, "{x} {y} {m1} {category} {patrolling} {orientable}\n")
                // todo: add bosses
                var edx, edy : float
                getEntityDirection(m1 & 3,edx,edy)
                enemies |> push <| new [[Enemy
                    pos = float2(ex,ey) + float2(0.5),
                    dir = float2(edx, edy),
                    category = Category enemy,
                    enemyCategory = category,
                    patrolling = patrolling,
                    mapItem = m1,
                    spriteIndex = enemyClasses[int(category)].spriteIndex,
                    health = enemyClasses[int(category)].hp,
                    radius = enemyClasses[int(category)].radius,
                    orientable = orientable
                ]]

def rotateTowardsPlayer ( var self:Enemy )
    self.dir = normalize(player.pos - self.pos)

def shoot ( var self:Enemy )
    with self
        var dxy = player.pos - pos
        let dist = length(dxy)
        dxy /= dist
        let tres = trace(pos.x,pos.y,dxy.x,dxy.y,dist,false)
        if tres.t >= dist
            let attackDamage = enemyClasses[int(enemyCategory)].attackDamage
            let attackDistance = enemyClasses[int(enemyCategory)].attackDistance
            let distanceFactor = clamp(1. -  dist / attackDistance, 0., 1.)
            let randomFactor = random_float(seed) * 0.3 // todo: tune?
            let damage = float(attackDamage) * (distanceFactor + randomFactor)
            let finalDamage = clamp ( int(damage), 3, attackDamage )
            player |> takeDamage(finalDamage)

def attack ( var self:Enemy )
    with self
        assume eclass = enemyClasses[int(enemyCategory)]
        let delay = eclass.attackDelay
        attackTimer = delay.x + random_float(seed)*(delay.y-delay.x)
        running = false
        let fireRate = eclass.attackFireRate / 16.
        self |> startAnimation(new Animation(eclass.attackSprites,false,false,fireRate))
        play_game_sound_2d(eclass.attackSound, pos, PAIN_SOUND_RADIUS)
        rotateTowardsPlayer(self)
        self |> shoot()

def canMoveTo ( self:Enemy; XY:float2 )
    with self
        let dplayer = length(player.pos - XY)
        if (dplayer < (radius + player.radius))
            // can't move into player slot, period
            return false
        return canMoveTo(XY,radius)

def move ( var self:Enemy; length,sideways:float )
    with self
        let oldxy = pos
        let XY = pos + dir*length + dir.yx*float2(-sideways,sideways)
        if self |> canMoveTo(float2(XY.x, pos.y))
            pos.x = XY.x
        if self |> canMoveTo(float2(pos.x, XY.y))
            pos.y = XY.y
        let newxy = floori(pos)
        let pcxy = floori(player.pos)
        let dplayer = length(player.pos - pos)
        if (newxy==pcxy) || (dplayer < radius + player.radius)
            pos = oldxy
            return

def getPrimaryDirection(dir:float2) : int2
    if abs(dir.x) > abs(dir.y)
        return dir.x > 0. ? int2(1,0) : int2(-1,0)
    else
        return dir.y > 0. ? int2(0,1) : int2(0,-1)

def getSecondaryDirection(dir:float2) : int2
    if abs(dir.x) > abs(dir.y)
        return dir.y > 0. ? int2(0,1) : int2(0,-1)
    else
        return dir.x > 0. ? int2(1,0) : int2(-1,0)

def update ( var self:Enemy )
    with self
        attackTimer = max ( attackTimer - 1. / 60. * frame_time, 0. )
        agroTimer = max ( agroTimer - 1. / 60. * frame_time, 0. )
        // agro resets if we see the player regardless of what we are doing
        if visibility_plane[OFS(floori(pos))]   // player sees us, so we may (or may not) be able to see them
            var dxy = normalize(player.pos - pos)
            var angle = dot(dxy,dir)
            if !orientable || angle>=0.1
                if agroTimer == 0.
                    let agroSound = enemyClasses[int(enemyCategory)].agroSound
                    play_game_sound_2d(agroSound, pos, AGRO_SOUND_RADIUS)
                agroTimer = AGRO_TIME
        if animation == null || running
            if agroTimer!=0. && attackTimer==0. && player.health>0 && visibility_plane[OFS(floori(pos))]
                // we try to shoot, if we are at the right distance
                let dist = length(player.pos - pos)
                let attackDistance = enemyClasses[int(enemyCategory)].attackDistance
                if dist>0. && dist<=attackDistance
                    self |> attack()
                    return
            if agroTimer!=0. && player.health>0 && visibility_plane[OFS(floori(pos))]
                // we rotate towards player
                let dist = length(player.pos - pos)
                let comfortDistance = enemyClasses[int(enemyCategory)].comfortDistance
                if dist > comfortDistance
                    // if we too far, we run
                    running = true
                else
                    // if we comfortable, we do nada
                    spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                    animation = null
                    running = false
            if agroTimer==0.
                // if we are not agroed, we just stand
                spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                animation = null
                running = false
        if running
            if animation == null
                self |> startAnimation(new Animation(enemyClasses[int(enemyCategory)].runSprites,true,orientable))
            if !run(self)
                // if we can't move, we just stand and watch player
                rotateTowardsPlayer(self)
                spriteIndex = enemyClasses[int(enemyCategory)].spriteIndex
                animation = null
                running = false

def run ( var self:Enemy )
    with self
        let speed = enemyClasses[int(enemyCategory)].speed * frame_time
        var tgt : float2
        if run.x==0.
            tgt = player.pos
        else
            tgt = run
        var runDir = tgt-pos
        let dist = length(runDir)
        runDir /= dist
        if run.x!=0.
            if dist<=speed
                // we reached the side target
                pos = run
                run = float2(0.)
                return true
            else
                // running to side target (todo: check if it became taken)
                dir = runDir
                self |> move(speed, 0.)
                return true
        var mainPos = pos + runDir * 0.5
        if self |> canMoveTo( mainPos )
            dir = runDir
            self |> move(speed, 0.)
            return true
        // we pick side target
        var primDir = getPrimaryDirection(runDir)
        var primPos = floor(pos) + float2(0.5) + float2(primDir)
        if self |> canMoveTo( primPos )
            run = primPos
            return true
        var secDir = getSecondaryDirection(runDir)
        var secPos = floor(pos) + float2(0.5) + float2(secDir)
        if self |> canMoveTo( secPos )
            run = secPos
            return true
        return false

def updateEnemies
    for enemy in enemies
        // very basic AI
        if enemy.category == Category enemy
            *enemy |> update()
        // animation
        if enemy.animation != null
            enemy.animation.timer += enemy.animation.rate * frame_time
            if enemy.animation.timer >= 1.0
                enemy.animation.timer = 0.
                if enemy.animation.spriteIndex >= enemy.animation.sprites |> length - 1
                    if enemy.animation.loop
                        // animation loops
                        enemy.animation.spriteIndex = 0
                    else
                        // animation ended (delete?)
                        enemy.spriteIndex = enemy.animation.sprites |> back
                        enemy.animation = null
                        return
                else
                    enemy.animation.spriteIndex += 1
                enemy.spriteIndex = enemy.animation.sprites[enemy.animation.spriteIndex]

def updateTimers
    for timer,index in timer_plane,count()
        if !timer.active
            continue
        let XY = int2(index & 63,index >> 6)
        if timer.isDoor
            if timer.opening
                if timer.t < 1.
                    timer.t += DOOR_OPEN_SPEED / 64. * frame_time
                else
                    timer.t += 1. / 60. * frame_time
                if timer.t >= 1.
                    collision_plane[index] = false
                if timer.t >= DOOR_STAYS_CLOSED
                    timer.t = DOOR_STAYS_CLOSED
                    timer.opening = false
            else
                if timer.t < 1.
                    timer.t -= DOOR_CLOSE_SPPED / 64. * frame_time
                else
                    timer.t -= 1./ 60. * frame_time
                if timer.t <= 1.
                    if !collision_plane[index]
                        var enemyTooCloseToDoor = false
                        for enemy in enemies
                            if enemy.category == Category enemy
                                let edist = abs(floori(enemy.pos)-XY)
                                if edist.x<=1 && edist.y<=1
                                    enemyTooCloseToDoor = true
                                    break
                        if enemyTooCloseToDoor || player|>isTooCloseToDoor(XY)
                            timer.t = DOOR_STAYS_CLOSED
                        else
                            collision_plane[index] = true
                            play_game_sound_2d(SoundName CLOSEDOORSND, float2(XY)+float2(0.5), DOOR_SOUND_RADIUS, DOOR_SOUND_PLAYBACK_RATE)
                            // TODO: remove dead body from doorway
                if timer.t <= 0.
                    timer.t = 0.
                    timer.active = false
                    assert(collision_plane[index])
        elif timer.isWall
            timer.t += 1. / 60. * frame_time
            if timer.t >= 1.
                let DXY = int2(timer.dx,timer.dy)
                let wallValue = level.plane0[index]
                level.plane0[index] = level.plane0[OFS(XY-DXY)]
                level.plane0[OFS(XY+DXY)] = wallValue
                level.plane1[index] = 0
                collision_plane[index] = false
                collision_plane[OFS(XY+DXY)] = true
                timer.steps -= 1
                if timer.steps>0 && !collision_plane[OFS(XY+DXY+DXY)]
                    // wall moves one more step
                    level.plane1[OFS(XY+DXY)] = 98
                    timer.t = 0.
                    timer_plane[OFS(XY+DXY)] = timer
                timer.active = false
        else
            // any random timer
            timer.t -= 1. / 60. * frame_time
            if timer.t <= 0.
                timer.t = 0.
                timer.active = false

var ENABLE_CHEAT_CODEDS = true

def updatePlayer
    player |> update()
    // update hud
    playerHoodTime += 1./60./10. * frame_time
    if playerHoodTime > 1.
        playerHoodTime -= 1.
    playerHealth = clamp(float(player.health) / 100., 0., 1.0)
    // note: the section bellow is for debugging only. It allows to save and load player position
    if !ENABLE_CHEAT_CODEDS
        return
    if is_key_pressed(VK_F1)
        to_log(LOG_INFO, "player was given everything\n")
        player.goldKey = true
        player.silverKey = true
        player.hasWeapon[int(WeaponType machineGun)] = true
        player.hasWeapon[int(WeaponType chainGun)] = true
        player.ammo = 199
        player.health = 200
    if is_key_pressed(VK_F9)
        sleep(100u)
        // spawn an enemy at 34-60
        let X = 34
        let Y = 61
        var category = EnemyCategory dog
        enemies |> push <| new [[Enemy
            pos = float2(X,Y) + float2(0.5),
            dir = float2(1,0),
            category = Category enemy,
            enemyCategory = category,
            patrolling = true,
            spriteIndex = enemyClasses[int(category)].spriteIndex,
            health = enemyClasses[int(category)].hp,
            orientable = true
        ]]
        print("spawn dog\n")
    if is_key_pressed(VK_F8)
        // spawn column
        let X = 34
        let Y = 60
        objects |> push <| new [[Entity
            category = Category prop,
            pos = float2(X,Y) + float2(0.5),
            spriteIndex = int(Props Tree) - 21
        ]]
        collision_plane[OFS(X,Y)] = true
    if is_key_pressed(VK_F10)
        if is_key_pressed(VK_LSHIFT) || is_key_pressed(VK_RSHIFT)
            if levelIndex<8
                switchLevel(8)  // HANS GROSSE
            else
                switchLevel(18) // DOCTOR SCHABBS
        else
            switchLevel(levelIndex+1)

def updateHud
    hudMessageTime -= 1./60. * frame_time
    if hudMessageTime < 0.
        hudMessageTime = 0.
        hudMessage = ""

def updateGame(dt:float)
    frame_time = dt / 16.0
    updatePalette()
    if dLevelFade != 0.
        return
    updateHud()
    updatePlayer()
    updateTimers()
    updateEnemies()

