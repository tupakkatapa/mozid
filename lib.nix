{ }:

let
  # Extract addon slug from URL
  # Supports formats like:
  # - https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/
  # - https://addons.mozilla.org/firefox/addon/vimium-ff/
  extractSlug = url:
    let
      # Use builtins.match to extract slug from URL
      match = builtins.match ".*/addon/([^/]+)/?.*" url;
    in
      if match != null then builtins.head match else null;

  # Fetch extension data from Mozilla API
  fetchExtensionData = slug:
    let
      apiUrl = "https://addons.mozilla.org/api/v5/addons/addon/${slug}/";
      response = builtins.fetchurl apiUrl;
      data = builtins.fromJSON (builtins.readFile response);
    in
      data;

in
rec {
  # Fetch extension UUID from slug or URL
  # Automatically detects if input is a slug or URL
  #
  # Note: Requires --impure flag when evaluating (e.g., nixos-rebuild)
  #
  # Example usage:
  #   mozid.lib.getExtensionId "vimium-ff"
  #   => "{d7742d87-e61d-4b78-b8a1-b469842139fa}"
  #   mozid.lib.getExtensionId "https://addons.mozilla.org/en-US/firefox/addon/vimium-ff/"
  #   => "{d7742d87-e61d-4b78-b8a1-b469842139fa}"
  #
  getExtensionId = input:
    let
      # Check if input looks like a URL
      isUrl = builtins.match "https?://.*" input != null;
      slug = if isUrl then extractSlug input else input;
    in
      if slug == null
      then throw "Failed to extract addon slug from: ${input}"
      else (fetchExtensionData slug).guid;

  # Generate Firefox ExtensionSettings from a list of addon slugs or URLs
  # Returns an attrset suitable for programs.firefox.package extraPolicies.ExtensionSettings
  #
  # Example usage:
  #   mozid.lib.mkExtensions [ "vimium-ff" "ublock-origin" ]
  #   => {
  #        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
  #          install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/vimium-ff/latest.xpi";
  #          installation_mode = "force_installed";
  #        };
  #        "uBlock0@raymondhill.net" = { ... };
  #      }
  #
  mkExtensions = inputs:
    let
      # Convert each input to an extension setting
      mkExtension = input:
        let
          # Extract slug from URL or use input as-is
          isUrl = builtins.match "https?://.*" input != null;
          slug = if isUrl then extractSlug input else input;
          uuid = getExtensionId input;
        in
          {
            name = uuid;
            value = {
              install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${slug}/latest.xpi";
              installation_mode = "force_installed";
            };
          };
    in
      builtins.listToAttrs (map mkExtension inputs);

  # Internal function for CLI use
  _cli = getExtensionId;
}
