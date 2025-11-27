# Jade Admin

**Jade Admin** is a powerful admin script for Roblox designed to provide easy-to-use commands for managing your game with ease. It includes various admin functions such as parts fling, fly, noclip, infinite jump, teleportation, and more. Whether you're a developer or a user, **Jade Admin** offers an intuitive set of commands to control in-game elements and player behaviors.

---

## Features

- **Fling Parts**: Fling parts and attach them to other players or characters in the game.
- **Fly**: Toggle flying mode and adjust fly speed.
- **Noclip**: Enable or disable noclip to pass through walls and obstacles.
- **Infinite Jump**: Enable infinite jumping, allowing you to jump higher and faster by spamming the spacebar.
- **Teleportation**:
  - `!goto <player name>`: Teleport to another player in the game.
  - `!respawn`, `!re`: Respawn your character.
  - `!rejoin`: Rejoin the current server.
  - `!serverhop` / `!shop`: Hop to a new server.
- **WalkSpeed & JumpPower**: Adjust walk speed and jump power of players.
- **Command Shortcuts**: Easily run commands through the chat with simple commands prefixed with `!`.

---

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/asvncc/Jade-Admin/refs/heads/main/main.lua"))()
```

---

## Commands

Here’s a list of the most useful commands you can use in your game.

### General Commands

- `!fly` / `!unfly`: Toggle flying mode on/off.
- `!noclip` / `!clip`: Toggle noclip (walk through walls) mode.
- `!infinitejump` / `!infjump`: Enable infinite jump to jump as high as you want by spamming spacebar.
- `!rejoin`: Rejoin the current server.
- `!serverhop` / `!shop`: Hop to another server with available space.
- `!respawn` / `!re`: Respawn your character.
- `!walkspeed <number>`: Set your walk speed to a specified value.
- `!jumppower <number>`: Set your jump power to a specified value.
- `!goto <player name>`: Teleport to another player’s location in the game.

### Parts Fling

- `!bringparts <player name>`: Attach and fling parts to the specified player.
- `!unbringparts`: Stop flinging parts and reset everything.

### Special Features

- **Fly Mode**: While flying, use **WASD** keys to move and **Spacebar** to rise, **LeftControl** (or **C**) to descend. Boost your flight with **Shift**.
- **Mobile Controls**: If on mobile, use the `Fly` button to toggle flying mode.
- **Infinite Jump**: Press **Spacebar** repeatedly to fly higher.
