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
  glob secrets/*.age | each {|f|
    rage --decrypt --identity {{ssh-key}} --output ($f | str replace '.age' '') $f
  } | ignore

[script('nu')]
encrypt:
  glob secrets/*.nix | each {|f|
    rage --armor --recipients-file {{ssh-key}}.pub --output ($f ++ ".age") $f
  } | ignore

update:
  nix flake update

test: decrypt
  sudo nixos-rebuild test --flake path:.#{{host}}

switch: decrypt
  sudo nixos-rebuild switch --flake path:.#{{host}}

boot: decrypt
  sudo nixos-rebuild boot --flake path:.#{{host}}

update-test: update test

update-switch: update switch

update-boot: update boot

# TODO: we shouldn't need to specify the pipe-operators feature here.
# Drop determinate nix?
darwin-switch: decrypt
  sudo darwin-rebuild switch --flake path:.#{{host}} --option extra-experimental-features 'nix-command flakes pipe-operators'
