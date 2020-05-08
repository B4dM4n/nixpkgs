{ buildPackages
, callPackage
}:

rec {
  # Maint version
  perl528 = callPackage ./common.nix {
    self = perl528;
    buildPerl = buildPackages.perl528;
    version = "5.28.2";
    sha256 = "1iynpsxdym4h76kgndmn3ykvwxhqz444xvaz8z2irsxkvmnlb5da";
  };

  # Maint version
  perl530 = callPackage ./common.nix {
    self = perl530;
    buildPerl = buildPackages.perl530;
    version = "5.30.2";
    sha256 = "128nfdxcvxfn5kq55qcfrx2851ys8hv794dcdxbyny8rm7w7vnv6";
  };

  # the latest Devel version
  perldevel = callPackage ./common.nix {
    self = perldevel;
    buildPerl = buildPackages.perldevel;
    version = "5.31.10";
    sha256 = "1gvv5zs54gzb947x7ryjkaalm9rbqf8l8hwjwdm9lbfgkpg07kny";
  };
}
