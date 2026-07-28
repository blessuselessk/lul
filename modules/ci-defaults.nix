# Establish _module.args.CI = false as the default for all classes.
# ci-runtime.nix (injected by GitHub Actions) overrides this to true with
# higher priority. Without this, the nixpkgs module system fails to resolve
# the `CI` argument in aspect modules (it goes to _module.args.CI rather than
# using the function-signature default, raising "attribute 'CI' missing").
{ lib, ... }:
{
  _module.args.CI = lib.mkDefault false;
}
