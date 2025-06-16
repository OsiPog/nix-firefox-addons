# Copied and adapted from https://gitlab.com/rycee/nur-expressions/-/blob/78ce8a0ab9e72a4127472e6343a92a33fbd12691/pkgs/firefox-addons/default.nix
{
  fetchurl,
  stdenv,
  lib,
  ...
}: {
  guid,
  slug,
  version,
  url,
  hash,
  permissions,
  license
}:
stdenv.mkDerivation {
  inherit version;
  pname = slug;

  src = fetchurl {
    inherit url;
    sha256 = builtins.convertHash {
      inherit hash;
      toHashFormat = "sri";
      hashAlgo = "sha256";
    };
  };

  preferLocalBuild = true;
  allowSubstitutes = true;

  buildCommand = ''
    dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
    mkdir -p "$dst"
    install -v -m644 "$src" "$dst/${guid}.xpi"
  '';

  meta = {
    mozPermissions = permissions;
    license = with lib.licenses; lib.getAttr license {
      "CC-BY-3.0" = cc-by-30;
      "MIT" = mit;
      "CC-BY-NC-ND-3.0" = cc-by-nc-nd-30;
      "cc-all-rights-reserved" = unfreeRedistributable;
      "CC-BY-SA-3.0" = cc-by-sa-30;
      "MPL-2.0" = mpl20;
      "CC-BY-NC-SA-3.0" = cc-by-nc-sa-30;
      "GPL-3.0-only" = gpl3Only;
      "BSD-2-Clause" = bsd2;
      "all-rights-reserved" = unfree;
      "CC-BY-NC-3.0" = cc-by-nc-30;
      "LGPL-3.0-only" = lgpl3Only;
      "CC-BY-ND-3.0" = cc-by-nd-30;
      "CC-BY-4.0" = cc-by-40;
      "CC-BY-NC-SA-4.0" = cc-by-nc-sa-40;
      "GPL-2.0-only" = gpl2Only;
      "CC-BY-NC-ND-4.0" = cc-by-nc-nd-40;
      "Apache-2.0" = asl20;
      "CC-BY-NC-4.0" = cc-by-nc-40;
      "MPL-1.1" = mpl11;
      "Unlicense" = unlicense;
      "CC-BY-SA-4.0" = cc-by-sa-40;
      "AGPL-3.0-only" = agpl3Only;
      "LGPL-2.1-only" = lgpl21Only;
      "ISC" = isc;
    };
  };
}
