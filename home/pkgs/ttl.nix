# ttl — TUI traceroute (github.com/lance0/ttl). Not in nixpkgs; packaged from
# the static release binaries (musl on Linux, so no patchelf needed).
{
  stdenv,
  lib,
  fetchurl,
}:

let
  version = "0.22.0";

  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/lance0/ttl/releases/download/v${version}/ttl-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "0q6iifrzzcfb0m7406lvgrabvpmvh3kih3wdj1iifrji2ps58dn6";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/lance0/ttl/releases/download/v${version}/ttl-aarch64-unknown-linux-musl.tar.gz";
      sha256 = "0cpp1sbiz3hav33i0xpin8qpwspa2gj98cgn75076r46688yw5z4";
    };
    x86_64-darwin = fetchurl {
      url = "https://github.com/lance0/ttl/releases/download/v${version}/ttl-x86_64-apple-darwin.tar.gz";
      sha256 = "0cblrab83rg5xxb2hjdjcrpgllx9a774f896jscrivhddsmqlfn5";
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/lance0/ttl/releases/download/v${version}/ttl-aarch64-apple-darwin.tar.gz";
      sha256 = "0cg4vnylba13zckr7c0q8zdn8z4i2z6r3dd01xfs5jqvrlqqfdh8";
    };
  };
in
stdenv.mkDerivation {
  pname = "ttl";
  inherit version;

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "ttl: unsupported system ${stdenv.hostPlatform.system}");

  sourceRoot = ".";
  dontBuild = true;
  dontConfigure = true;
  dontFixup = stdenv.hostPlatform.isLinux; # static musl binary — nothing to patch

  installPhase = ''
    runHook preInstall
    install -Dm755 "$(find . -name ttl -type f | head -1)" "$out/bin/ttl"
    runHook postInstall
  '';

  meta = {
    description = "Modern TUI traceroute";
    homepage = "https://github.com/lance0/ttl";
    license = lib.licenses.mit;
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
