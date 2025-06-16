{
  runCommand,
  nushell,
  lib,
  ...
}: let
  inherit (builtins) fromJSON readFile;
  inherit (lib) pipe getExe;
in
  yamlPath:
    pipe yamlPath [
      # convert to json file using nushell 'open file.yaml | to json --raw | save $out'
      (yamlPath: runCommand "from-yaml-to-json" {} "${getExe nushell} -c \"open ${yamlPath} | to json --raw | save $out\"")
      readFile # read the file
      fromJSON # and json -> nix attrset
    ]
