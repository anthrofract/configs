# configs

![](https://i0.wp.com/globalpragmatica.com/wp-content/uploads/2010/10/Mandelbrot.jpeg)

My personal configs for NixOS, KDE Plasma, Helix, Tmux, Ghostty, Nushell, and more.

## NixOS setup

### Install the base os

- Download the latest [NixOS Plasma ISO](https://nixos.org/download/).
- Flash it to a USB drive.
- Boot into it and install as normal.

### Install the full system

This repo contains encrypted secrets. To decrypt them, you must first obtain the `id_ed25519_anthrofract` SSH key pair files and place them in `~/.ssh`.

We can now install the full system. These commands will clone the repo, decrypt the secrets, apply the NixOS configuration, and link the configs into `~`. Fill in the host value with the hostname from the hosts dir that you are installing.

```bash
cd ~
nix-shell -p git jujutsu just nushell rage --extra-experimental-features 'nix-command flakes pipe-operators'
jj git clone --colocate https://github.com/anthrofract/configs.git
cd configs
just --set host "<host>" boot
sudo reboot
```
