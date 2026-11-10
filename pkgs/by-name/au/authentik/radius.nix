{
  buildGoModule,
  mkGoOutpost,
}:
mkGoOutpost buildGoModule {
  outpostName = "radius";

  meta.description = "Authentik radius outpost which is used for the external radius API";
}
