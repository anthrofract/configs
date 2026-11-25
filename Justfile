set shell := ["nu", "-c"]

host := `hostname`
ssh-key := "~/.ssh/id_ed25519_anthrofract"
minimal-iso := "/tmp/nixos-minimal-x86_64-linux.iso"

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

test: decrypt
  nh os test path:. -H {{host}}

build: decrypt
  nh os build path:. -H {{host}}

build-remote builder="valhalla": decrypt
  nh os build path:. -H {{host}} --build-host {{builder}} --use-substitutes

switch: decrypt
  nh os switch path:. -H {{host}}

switch-remote builder="valhalla": decrypt
  nh os switch path:. -H {{host}} --build-host {{builder}} --use-substitutes

boot: decrypt
  nh os boot path:. -H {{host}}

deploy target: decrypt
  nh os switch path:. -H {{target}} --target-host {{target}} --use-substitutes

deploy-boot target: decrypt
  nh os boot path:. -H {{target}} --target-host {{target}} --use-substitutes
  ssh -t {{target}} sudo systemctl reboot

update: decrypt
  nix flake update

darwin-switch: decrypt
  nh darwin switch path:. -H {{host}}

[script('nu')]
download-minimal-iso:
  let url = "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso"
  let expected = curl --fail --silent --location $"($url).sha256" | split row " " | first
  curl --fail --location --output {{minimal-iso}} $url
  if (sha256sum {{minimal-iso}} | split row " " | first) != $expected {
    rm {{minimal-iso}}
    error make { msg: "The downloaded ISO doesn't match its published checksum, try again" }
  }

gimle-build-iso: decrypt
  nix build path:.#nixosConfigurations.gimle.config.system.build.isoImage

[script('nu')]
flash iso:
  let drive = lsblk --json --bytes --nodeps --output PATH,SIZE,MODEL,TRAN | from json | get blockdevices
    | where tran == "usb" and size > 0
    | input list --display {|d| $"($d.path)  ($d.size | into filesize)  ($d.model)" } "Erase and flash which USB drive?"
  if $drive != null { sudo dd if={{iso}} $"of=($drive.path)" bs=4M conv=fsync oflag=direct status=progress }

flash-minimal-iso: download-minimal-iso (flash minimal-iso)

flash-gimle-iso: gimle-build-iso
  just flash $"result/(nix eval --raw path:.#nixosConfigurations.gimle.config.image.filePath)"

[script('nu')]
install-anywhere host target: decrypt
  let files = mktemp --directory
  let home = $"($files)/home/($env.USER)"
  mkdir $"($home)/.ssh"
  cp {{ssh-key}} {{ssh-key}}.pub $"($home)/.ssh"
  chmod 700 $home $"($home)/.ssh"
  let origin = jj git remote list | parse "{name} {url}" | where name == "origin" | get url.0
  jj git clone --colocate $origin $"($home)/configs"
  let ok = try {
    nix run nixpkgs#nixos-anywhere -- --flake path:.#{{host}} --target-host root@{{target}} --extra-files $files --chown $"/home/($env.USER)" 1000:100
    true
  } catch { false }
  rm --recursive $files
  if not $ok { exit 1 }
