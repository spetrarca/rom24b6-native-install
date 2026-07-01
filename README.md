# QuickMUD / ROM 2.4b6 Native Install

QuickMUD is derived from ROM 2.4b6, Merc 2.1, and DikuMUD. This fork is set up
for a native Ubuntu VM install: clone the repo, compile the C source on the VM,
and run the server directly from the checkout.

## What This Includes

QuickMUD is a mostly stock ROM 2.4b6 codebase with these major additions:

- OLC 1.81
- Lope's Color 2.0
- Erwin's Copyover
- Erwin's Noteboard
- Color Login

The area editor files are included. See `area/olc.hlp` and `doc/changes.olc`
for OLC notes.

## Ubuntu VM Install

On a fresh Ubuntu VM:

```sh
sudo apt update
sudo apt install -y git build-essential libcrypt-dev
git clone https://github.com/spetrarca/rom24b6-native-install.git
cd rom24b6-native-install
./install-rom24b6.sh
./run-rom24b6.sh start
```

The server listens on port `4000` by default. To use a different port:

```sh
ROM_PORT=5000 ./run-rom24b6.sh start
```

Connect with a MUD client or telnet:

```sh
telnet localhost 4000
```

## Managing The Server

```sh
./run-rom24b6.sh status
./run-rom24b6.sh log
./run-rom24b6.sh stop
./run-rom24b6.sh restart
```

The install and run helpers create the runtime directories the game writes into:
`log/`, `player/`, and `gods/`. The run helper writes its pid to `rom.pid` and
logs to `log/rom.log`.

For an Azure VM, also open TCP `4000` in the VM network security group and use a
non-root Linux user to run the game.

## VM Operations

The Azure VM runs the game through `rom24-quickmud.service`. Repo-owned systemd
unit files live in `ops/systemd/`. To install or refresh them on the VM:

```sh
sudo ./ops/systemd/install-rom24-systemd.sh
```

That enables `rom24-quickmud-restart.timer`, which restarts the game daily at
`10:00 UTC` to clear transient world state such as shop inventory and loose
objects.

To update the Azure VM without a full redeploy, run this from an authenticated
local checkout:

```sh
./deploy-to-vm.sh
```

The deploy helper exports the committed Git tree, syncs it to
`/opt/rom24-quickmud`, rebuilds `area/rom` on the VM, and restarts the systemd
service. It preserves runtime data in `player/`, `gods/`, and `log/`.

For a host that already has GitHub access configured, the VM can update itself:

```sh
ROM_DEPLOY_REMOTE_URL=git@github.com:spetr86/sturdy-spoon.git ./deploy-rom24b6.sh
```

The in-VM deploy helper fetches the configured branch, fast-forwards the
checkout, rebuilds `area/rom`, and restarts the systemd service. It also
preserves runtime data and does not run `git clean` or `git reset --hard`. If
builders have changed tracked area files directly on the VM, commit and push
those changes before deploying.

## First Immortal

This repo does not ship with a default player credential.

To create the first immortal, start the game, create a mortal character, play at
least to level 2, stop the server, then edit that character's file under
`player/` to raise the level, trust, and security. For an implementor, set
`Levl 60`, `Tru  60`, and `Sec  9`. After that first immortal exists, use
in-game commands to advance other builders.

## Content Editing

QuickMUD includes OLC. Common builder commands include:

- `redit` for rooms
- `oedit` for objects
- `medit` for mobiles/NPCs
- `aedit` for areas
- `mpedit` for mob programs
- `hedit` for help entries

ROM/QuickMUD still uses prototype data files under `area/`, so keep the repo in
Git and commit content changes as you build.

## License Notes

This is the ROM 2.4 beta version of Merc 2.1 base code. Read the license files
in `doc/`, especially `doc/rom.license`, `doc/license.txt`, and
`doc/license.doc`, before running a public game.

See the other README files in this repository for historical project notes.
