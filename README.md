# configs

![](https://i0.wp.com/globalpragmatica.com/wp-content/uploads/2010/10/Mandelbrot.jpeg)

My personal configs for NixOS, KDE Plasma, Neovim, Tmux, Ghostty, Nushell, and more.

## NixOS setup

Hosts are installed over the network with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere), driven from a machine that already has this repo. The host's [disko](https://github.com/nix-community/disko) config partitions the target, so **its disks are wiped**.

### Requirements

- On the installing machine: this repo and the `id_ed25519_anthrofract` SSH key pair in `~/.ssh`, which decrypts the secrets.
- A host config in `hosts/<host>/` with its disko layout and `hardware.nix`.
- The repo pushed to GitHub. The target gets a fresh clone of `origin`.

### Flash the installer

Plug in a USB drive, then run:

```sh
just flash-minimal-iso
```

This downloads the latest NixOS minimal ISO, verifies its checksum, and asks which USB drive to erase and flash.

### Boot the target

Boot the target from the USB drive, then run these on its console:

```bash
nmtui              # Wi-Fi only
sudo passwd root   # nixos-anywhere asks for this once
ip -4 addr         # note the IP
```

### Install

On the installing machine:

```sh
just install-anywhere <host> <ip>
```

This wipes the target's disks, builds and installs the host's system, copies the repo to `~/configs` and the SSH key pair to `~/.ssh`, then reboots. Remove the USB drive when the target restarts.

### After the first boot

1. Log in with the password from `initialHashedPassword` in `config/secrets.nix`.
2. If the host was installed before, delete its old node in the Tailscale admin console. Then run `sudo tailscale up`.
3. Update the host's entries under `config.machines` in `config/secrets.nix`:
   - `ssh.hostKey`: the output of `cat /etc/ssh/ssh_host_ed25519_key.pub`
   - `syncthing.id`: the output of `syncthing device-id --home ~/.config/syncthing`
4. Run `just encrypt`, commit, and push. Then redeploy the other hosts so they trust the new keys: run `just switch` on the local host and `just deploy <host>` for remote ones.

## Gimle: ephemeral offline system

Gimle is a live system for sensitive offline work. Networking, Bluetooth, and audio are disabled, and nothing persists after shutdown. It boots into the Hyprland desktop with Dux, and includes YubiKey and OpenPGP tools, KeePassXC, and Sparrow.

Plug in a USB drive, then build the ISO and flash it:

```sh
just flash-gimle-iso
```

Boot from the USB drive and choose "Gimle Live Hyprland", or "Gimle Live Plasma". It logs in automatically.
