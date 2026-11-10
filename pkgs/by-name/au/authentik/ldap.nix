{
  buildGoModule,
  mkGoOutpost,
}:
mkGoOutpost buildGoModule {
  outpostName = "ldap";

  meta.description = "Authentik ldap outpost which is used for the external ldap API";
}
