set shell := ["nu", "-c"]

host := `hostname`
ssh-key := "~/.ssh/id_ed25519_anthrofract"

[script('nu')]
default:
  match (uname | get kernel-name) {
    "Linux" => { just switch },
    "Darwin" => { just darwin-switch },
    _ => { print "Unsupported OS"; exit 1 }
  }

fmt:
  fd -e nix -X nixfmt

[script('nu')]
decrypt:
  glob config/*.age | each {|f|
    rage --decrypt --identity {{ssh-key}} --output ($f | str replace '.age' '') $f
  } | ignore

[script('nu')]
encrypt:
  glob config/*.nix | each {|f|
    rage --armor --recipients-file {{ssh-key}}.pub --output ($f ++ ".age") $f
  } | ignore

test: decrypt diff
  sudo nixos-rebuild test --flake path:.#{{host}}

switch: decrypt diff
  sudo nixos-rebuild switch --flake path:.#{{host}}

boot: decrypt diff
  sudo nixos-rebuild boot --flake path:.#{{host}}

update:
  nix flake update

[script('nu')]
diff:
  let new_system = match (uname | get kernel-name) {
    "Linux" => (nix build --no-link --print-out-paths path:.#nixosConfigurations.{{host}}.config.system.build.toplevel | str trim),
    "Darwin" => (nix build --no-link --print-out-paths path:.#darwinConfigurations.{{host}}.system --option extra-experimental-features 'nix-command flakes pipe-operators' | str trim),
    _ => { print "Unsupported OS"; exit 1 }
  }
  dix /run/current-system $new_system

update-test: update test

update-switch: update switch

update-boot: update boot

# TODO: we shouldn't need to specify the pipe-operators feature here.
# Drop determinate nix?
darwin-switch: decrypt diff
  sudo darwin-rebuild switch --flake path:.#{{host}} --option extra-experimental-features 'nix-command flakes pipe-operators'

[script('nu')]
lily58-update:
  with-env {
    UPDATE_NIX_ATTR_PATH: "lily58-firmware"
    UPDATE_WEST_ROOT: "packages/lily58-firmware/config"
  } {
    nix run path:.#lily58-update
  }

lily58-build:
  nix build --no-link path:.#lily58-firmware

[script('nu')]
lily58-flash side='':
  if "{{side}}" == "" {
    nix run path:.#lily58-flash
  } else {
    nix run path:.#lily58-flash -- "{{side}}"
  }
