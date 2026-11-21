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

build: decrypt
  nh os build path:. -H {{host}}

build-remote builder="valhalla": decrypt
  nh os build path:. -H {{host}} --build-host {{builder}} --use-substitutes

test: decrypt
  nh os test path:. -H {{host}}

switch: decrypt
  nh os switch path:. -H {{host}}

switch-remote builder="valhalla": decrypt
  nh os switch path:. -H {{host}} --build-host {{builder}} --use-substitutes

boot: decrypt
  nh os boot path:. -H {{host}}

deploy target: decrypt
  nh os switch path:. -H {{target}} --target-host {{target}} --use-substitutes

update: decrypt
  nix flake update

update-test: update test

update-switch: update switch

update-boot: update boot

darwin-switch: decrypt
  nh darwin switch path:. -H {{host}}

gimle-build-iso: decrypt
  nix build path:.#nixosConfigurations.gimle.config.system.build.isoImage
