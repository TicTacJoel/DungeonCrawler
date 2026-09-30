# Wipeout Party — MultiplayerRaid

## Project Overview
2D pixel-art cooperative multiplayer dungeon crawler. 1–4 players select races, classes, progress through dungeons levels, fight enemies and bosses using 4 class-specific skills with cooldowns and equipping items which they receive from looting enemies or lootboxes gaines from bosses or achievements. Built in Godot 4.6 (ENet networking).

## Target Features
- 1–4 player co-op (ENet multiplayer)
- Procedurally generated dungeons with enemies and bosses, descending via stairs
- Multiple playable races and classes, each with 4 (unique) skills
- Skill cooldowns, boss health bars
- Stat progression and level system (planned)
- Loot boxes from bosses / achievements (planned)
- Player health bar (top-left) + ally bars (side, WIP)
- Skill bar at bottom of screen

## Architecture

### Autoloads
| Name | File | Purpose |
|------|------|---------|
| `Lobby` | `Scenes/UI/Menus/lobby.gd` | ENet server/client creation, PORT=7000, MAX_CONNECTIONS=3 |
| `PlayerManager` | `Scripts/Autoloads/PlayerManager.gd` | Centralized player data (id, class, health, position), `local_player_class`; signals: player_added, player_removed, player_health_changed |
| `Globals` | `Scripts/Autoloads/Globals.gd` | `isSingleplayer`, `isDebug` flags set by the main menu (debug auto-selects Mage) |
| `EventBus` | `Scripts/Autoloads/EventBus.gd` | Global signals: `player_earned_achievement` (commentator), `spawn_loot_box`, `safe_room_status_changed` |

Non-autoload globals: `Constants` (`Scripts/Utils/contants.gd` — scene/skin/icon/spell resource paths), `HelperFunctions` (`Scripts/Utils/helper_functions.gd` — `ClientInterpolate()`), `ClassData` (`Scripts/Autoloads/ClassData.gd`, a Resource despite the folder).

### Key Scripts
| Script | Extends | Role |
|--------|---------|------|
| `Scenes/Actors/player/player.gd` | CharacterBody2D | Movement, spell casting (`cast_spell` → `rpc_cast_spell`), health, camera, multiplayer authority |
| `Scripts/Autoloads/ClassData.gd` | Resource | Class definitions (stats, skin, icon, color, spells); `get_class_by_type()` |
| `Resources/Data/SpellData.gd` | Resource | Spell = targeting + delivery + shape + effects + cosmetics components |
| `Resources/Data/MonsterData.gd` | Resource | Reusable enemy/boss stat block scaled by `level` |
| `Resources/Data/BossAttackData.gd` | Resource | Boss attack: spell, telegraph time, cooldown, `min_level` unlock |
| `Resources/Data/AchievementData.gd` / `ItemData.gd` | Resource | Achievement / item definitions |
| `Scenes/UI/Menus/menu/main_menu.gd` | Control | Singleplayer / Debug / Multiplayer entry |
| `Scenes/UI/Menus/menu/menu.gd` | Node | Lobby: class selection, player list, kick, `start_game` RPC, `change_level()` on `level_complete` |
| `Scenes/World/level.gd` | Node2D | Server spawns all players via PlayerSpawner; `level_complete` signal |
| `Scenes/World/level_01/player_spawner.gd` | MultiplayerSpawner | Spawns class scene from PlayerManager; round-robin `spawn_points` |
| `Scenes/World/dungeon_generator.gd` | Node2D | Procedural dungeon (see below) |
| `Scenes/World/Rooms/room.gd` | Node2D (`Room`) | Room base: `open_side()` carves a doorway, spawn point getters |
| `Scenes/World/Rooms/stairs_exit.gd` | Area2D | Exit stairs: activates when ≥ n-1 players stand in it (server) |
| `Scenes/Actors/enemies/regular/enemy.gd` | CharacterBody2D (`Enemy`) | Chase AI, take_damage, die |
| `Scenes/Actors/enemies/ranged/ranged_caster.gd` | Enemy | Keeps distance, casts `monster_data.spells[0]` |
| `Scenes/Actors/enemies/boss/boss.gd` | CharacterBody2D (`Boss`) | State machine (chase → telegraph → attack → recover), health bar, drops loot box |
| `Scenes/Attacks/projectile.gd` / `spell_area.gd` | Area2D | Runtime nodes created by spell deliveries |
| `Scenes/UI/SpellBar/spell_bar.gd` / `spell_button.gd` | HBoxContainer / Button | Spell buttons, hotkeys (spell_1–4), cooldown clock |
| `Scenes/UI/PlayerFrame/player_frames.gd` / `player_frame.gd` | VBoxContainer / PanelContainer | Party health bars driven by PlayerManager signals |

### Spell System (`Scripts/Spells/`)
`SpellData` (`.tres` in `Resources/Spells/Definitions/`) is composed of:
- **Targeting** (`Targeting/`): mouse, facing, self, closest enemy, closest ally
- **Delivery** (`Delivery/`): instant, projectile, placed, aura — `delivery.execute(caster, spell, origin, target_point)`
- **Shape** (`Shapes/`): point, circle, cone, line — finds targets by group (`affects_group`)
- **Effects** (`Effects/`): damage, heal, knockback, status, teleport
- **Cosmetics** (`SpellCosmetics.gd`): cast/impact animation and FX

`SpellResolver.resolve_at()` runs shape → effects → impact cosmetics and is shared by all deliveries. Enemies and bosses use the same pipeline.

- Shapes are geometry queries against groups, **not** physics bodies. `SpellShape.get_outline()` provides a polygon; `ShapeTelegraph` (`Scenes/Attacks/shape_telegraph.gd`) draws it. With *Debug → Visible Collision Shapes* on, every resolved shape briefly flashes yellow.
- `is_caster_anchored()` (cone, line): instant deliveries resolve these at the caster and use the aim only as direction.
- Projectiles stop at walls (Environment layer) unless `DeliveryProjectile.passes_through_walls`.
- `EffectTeleport` sweeps the target's collider and stops at `blocked_by` layers (default Environment).
- Boss attacks lock their aim when the telegraph starts; the telegraph fills up over `telegraph_time`, and leaving the drawn area dodges it.

### Dungeon Generation
`Scenes/World/dungeon_level/dungeon_level.tscn` is the level the lobby starts (`menu.tscn` → `level_scene`). `level_01.tscn` is a hand-made debug/test level and is no longer used by the menu.

`DungeonGenerator`:
1. Server rolls a seed and RPCs it (`rpc_generate`, call_local); every peer generates the identical layout locally. Rooms/enemies are not replicated.
2. Random walk on a grid (with backtracking) → entrance, `general_room_count` general rooms, exit. The room before the exit becomes the BOSS room.
3. Rooms are placed `room_spacing` apart; `open_side()` carves a `door_width` doorway and `_build_corridor()` adds floor + side walls between rooms.
4. Enemies (`enemy_scenes`, `enemies_per_room`, `dungeon_level`) spread over each room's `EnemySpawnPoints`; boss at boss room center. Spawned nodes get explicit names (`Enemy_N`, `Boss`) so node paths match across peers.
5. Entrance `PlayerSpawnPoints` are handed to `PlayerSpawner`; exit `StairsArea.stairs_activated` → `level_complete` → menu starts a fresh dungeon.

Room scenes (`Scenes/World/Rooms/room_entrance|general|exit.tscn`) are 320×192 blockouts: `Floor` ColorRect, collision-only `Walls/North|South|East|West`, spawn point containers.

### Multiplayer Sync Strategy
- **Position**: `target_position` synced via MultiplayerSynchronizer, interpolated by `ClientInterpolate()`
- **Animations / flip_h**: MultiplayerSynchronizer
- **Class data**: RPC (`sync_class`, `sync_class_to_remote`); lobby syncs via `sync_player_class`
- **Dungeon layout**: seed RPC, deterministic local generation
- **Enemies / boss**: server-authoritative. Every peer instances them at identical paths (deterministic generation); only the server runs AI, movement, `take_damage` and death. MultiplayerSynchronizer replicates `sync_position` (clients interpolate), `health` and `Sprite2D:flip_h`. Attacks (`rpc_cast_spell`, `rpc_begin_telegraph` / `rpc_execute_attack`), hit flashes and deaths (`rpc_die`) are RPC'd call_local
- **Player health**: owner-authoritative. `take_damage`/`heal` only apply on the player's own peer (hits resolve on every peer, but only the owner sees the true position); `current_health` is replicated
- **Spell nodes** (projectiles, areas, FX) are parented to the caster's level (`SpellDelivery.world_of()`, group `level`), not the lobby `current_scene`
- **Interactable state** (door, bridge, pressure plate, chest, key_door): MultiplayerSynchronizer on `is_open` / `is_locked` / `locked_open` / `is_down`
- **Pushable objects**: Authority-request RPC system — clients request, server grants via `set_pushable_owner`

### Physics Layers
1. Environment  2. Player  3. Interactable  4. Enemy  5. Pushable

### Input Actions
`move_left`, `move_right`, `move_up`, `move_down`, `interact`, `spell_1`–`spell_4`

## Classes
| Class | HP | Speed | Spells | Status |
|-------|-----|-------|--------|--------|
| Druid | 100 | 200 | Placeholder (Fireball, Frostbolt, Arcane Explosion, Blink) | Active |
| Mage | 80 | 200 | Fireball, Frostbolt, Arcane Explosion, Blink | Active |
| Necromancer | 80 | 200 | Placeholder (same as Mage) | Active |
| Rogue | 90 | 250 | Backstab, Poison Strike, Fan of Knives, Stealth | Active |
| Hunter | — | — | — | Disabled |
| Priest | — | — | — | Disabled |
| Warrior | — | — | — | Disabled |

## Enemies
| Scene | Script | Notes |
|-------|--------|-------|
| `goblin_spear.tscn` | enemy.gd | Melee chaser, `goblin_spear_data.tres` |
| `spitter.tscn` | ranged_caster.gd | Ranged, casts `enemy_arcane_bolt`, `spitter_data.tres` |
| `boss.tscn` | boss.gd | `boss_data.tres`, attacks: melee swipe, ground slam |

## Scene Layout
```
main_menu.tscn → menu.tscn (lobby) → dungeon_level.tscn
										├── PlayersContainer
										├── PlayerSpawner (MultiplayerSpawner)
										├── DungeonGenerator
										│   ├── Room_x_y (entrance / general / boss / exit)
										│   └── Corridor_N
										└── UI (CanvasLayer)
											├── SpellBar
											└── PlayerFrames
```

## Player Variants
`player.tscn` is the base. `druid.tscn` and `wizard.tscn` inherit it and swap the Sprite2D texture. Mage, Necromancer and Rogue all use `wizard.tscn`; `apply_class_visuals()` swaps the skin at runtime.

## Known Issues / WIP
- Ally health bar panel (`player_frames.gd`) is work-in-progress
- Druid and Necromancer use Mage's spells as placeholders
- Enemies are not spawned via MultiplayerSpawner, so late joiners mid-level are not supported
- Enemy detection areas (spitter 260, boss 220) ignore walls, so enemies can aggro from adjacent rooms
- Room art is placeholder blockout (flat ColorRect floor, invisible walls); dungeon level has no lighting yet
- `dungeon_level` does not increase when descending — every new dungeon is level 1
- `spawn_loot_box` is emitted by the boss but nothing listens yet
- No stat progression / XP system yet (enemies have `experience` but nothing consumes it)
