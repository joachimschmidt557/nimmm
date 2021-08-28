(import
  (
    fetchTarball {
      url = "https://github.com/edolstra/flake-compat/archive/12c64ca55c1014cdc1b16ed5a804aa8576601ff2.tar.gz";
      sha256 = "hY8g6H2KFL8ownSiFeMOjwPC8P0ueXpCVEbxgda3pko=";
    })
  {
    src = ./.;
  }).defaultNix
