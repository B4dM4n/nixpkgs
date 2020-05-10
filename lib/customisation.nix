{ lib }:

rec {


  /* `overrideDerivation drv f' takes a derivation (i.e., the result
     of a call to the builtin function `derivation') and returns a new
     derivation in which the attributes of the original are overridden
     according to the function `f'.  The function `f' is called with
     the original derivation attributes.

     `overrideDerivation' allows certain "ad-hoc" customisation
     scenarios (e.g. in ~/.config/nixpkgs/config.nix).  For instance,
     if you want to "patch" the derivation returned by a package
     function in Nixpkgs to build another version than what the
     function itself provides, you can do something like this:

       mySed = overrideDerivation pkgs.gnused (oldAttrs: {
         name = "sed-4.2.2-pre";
         src = fetchurl {
           url = ftp://alpha.gnu.org/gnu/sed/sed-4.2.2-pre.tar.bz2;
           sha256 = "11nq06d131y4wmf3drm0yk502d2xc6n5qy82cg88rb9nqd2lj41k";
         };
         patches = [];
       });

     For another application, see build-support/vm, where this
     function is used to build arbitrary derivations inside a QEMU
     virtual machine.
  */
  overrideDerivation = drv: f:
    let
      newDrv = derivation (drv.drvAttrs // (f drv));
    in lib.flip (extendDerivation true) newDrv (
      { meta = drv.meta or {};
        passthru = if drv ? passthru then drv.passthru else {};
      }
      //
      (drv.passthru or {})
      //
      (if (drv ? crossDrv && drv ? nativeDrv)
       then {
         crossDrv = overrideDerivation drv.crossDrv f;
         nativeDrv = overrideDerivation drv.nativeDrv f;
       }
       else { }));


  /* `makeOverridable` takes a function from attribute set to attribute set and
     injects `override` attribute which can be used to override arguments of
     the function.

       nix-repl> x = {a, b}: { result = a + b; }

       nix-repl> y = lib.makeOverridable x { a = 1; b = 2; }

       nix-repl> y
       { override = «lambda»; overrideDerivation = «lambda»; result = 3; }

       nix-repl> y.override { a = 10; }
       { override = «lambda»; overrideDerivation = «lambda»; result = 12; }

     Please refer to "Nixpkgs Contributors Guide" section
     "<pkg>.overrideDerivation" to learn about `overrideDerivation` and caveats
     related to its use.
  */
  makeOverridable = makeOverridableLayer null;


  makeOverridableLayer = makeOverridableLayerWithAlias null;


  makeOverridableLayerWithAlias = alias: layer: f: origArgs:
    let
      result = f origArgs;

      setOrRemoveLayers = v: s:
        if v == [ ]
        then removeAttrs s [ "__overrideLayers" ]
        else s // { __overrideLayers = v; };

      # Creates a functor with the same arguments as f
      copyArgs = g: lib.setFunctionArgs g (lib.functionArgs f);
      # Changes the original arguments with (potentially a function that returns) a set of new attributes
      overrideWith = newArgs: origArgs // (if lib.isFunction newArgs then newArgs origArgs else newArgs);

      # Re-call the function but with different arguments
      overrideArgs = newArgs: overrideArgsResult newArgs lib.id;
      # Change the result of the function call by applying g to it
      overrideResult = overrideArgsResult { };
      # Re-call the function but with different arguments and also change the result of the function call by applying g to it
      overrideArgsResult = a: g: makeOverridableLayerWithAlias alias layer (copyArgs (args: g (f args))) (overrideWith a);

      # Override each named overridable of the given mapping from name to arguments.
      # If a layer name is not found throw an error message.
      overrideLayersAttrs = layers:
        let
          newArgs = if layer == null then origArgs else layers.${layer} or { };
          newLayers = if layer == null then layers else removeAttrs layers [ layer ];
        in
        overrideArgsResult
          newArgs
          (x:
            if newLayers != { }
            then
              if x ? overrideLayers
              then x.overrideLayers newLayers
              else throw "override layers ${builtins.toJSON (lib.attrNames newLayers)} not found"
            else x);
      # Override each nested overridable which has a name with the arguments from the list.
      # The list is applied to the nested overridables first to last onto bottom to top,
      # thus the first list entry overrides the most nested named overridable.
      #
      # This is achieved by storing the list into the __overrideLayers attribute in the most
      # most nested result and removing the first entry of the list at each named overridable.
      overrideLayersList = layers:
        let
          o = overrideResult (x:
            if x ? overrideLayers
            # Pass down the original list of layers
            then x.overrideLayers layers
            # Store the original list of layers for the upper layers to read
            else setOrRemoveLayers layers x
          );
          layers' = o.__overrideLayers or [ ];
          head = if layers' == [ ] then { } else lib.head layers';
          tail = if layers' == [ ] then [ ] else lib.tail layers';
        in
        if layer == null
        then o
        else setOrRemoveLayers tail (o.override head);
    in
    if lib.isAttrs result then
      result // rec {
        override = overrideArgs;
        overrideDerivation = fdrv: overrideResult (x: lib.overrideDerivation x fdrv);
        overrideAttrs =
          if result ? overrideAttrs
          then fdrv: overrideResult (x: x.overrideAttrs fdrv)
          else overrideArgs;
        overrideLayerName = l: fdrv: overrideLayers { ${l} = fdrv; };
        overrideLayers = layers:
          if lib.isAttrs layers then overrideLayersAttrs layers
          else if lib.isList layers then overrideLayersList layers
          else throw "value is a ${builtins.typeOf layers} while a set or a list was expected";
        ${alias} = override;
      }
    else if lib.isFunction result then
      # Transform the result into a functor while propagating its arguments
      lib.setFunctionArgs result (lib.functionArgs result) // {
        override = overrideArgs;
      }
    else result;


  /* Call the package function in the file `fn' with the required
    arguments automatically.  The function is called with the
    arguments `args', but any missing arguments are obtained from
    `autoArgs'.  This function is intended to be partially
    parameterised, e.g.,

      callPackage = callPackageWith pkgs;
      pkgs = {
        libfoo = callPackage ./foo.nix { };
        libbar = callPackage ./bar.nix { };
      };

    If the `libbar' function expects an argument named `libfoo', it is
    automatically passed as an argument.  Overrides or missing
    arguments can be supplied in `args', e.g.

      libbar = callPackage ./bar.nix {
        libfoo = null;
        enableX11 = true;
      };
  */
  callPackageWith = autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
    in makeOverridable f (auto // args);


  /* Like callPackage, but for a function that returns an attribute
     set of derivations. The override function is added to the
     individual attributes. */
  callPackagesWith = autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
      origArgs = auto // args;
      pkgs = f origArgs;
      mkAttrOverridable = name: _: makeOverridable (newArgs: (f newArgs).${name}) origArgs;
    in
      if lib.isDerivation pkgs then throw
        ("function `callPackages` was called on a *single* derivation "
          + ''"${pkgs.name or "<unknown-name>"}";''
          + " did you mean to use `callPackage` instead?")
      else lib.mapAttrs mkAttrOverridable pkgs;


  /* Add attributes to each output of a derivation without changing
     the derivation itself and check a given condition when evaluating. */
  extendDerivation = condition: passthru: drv:
    let
      outputs = drv.outputs or [ "out" ];

      commonAttrs = drv // (builtins.listToAttrs outputsList) //
        ({ all = map (x: x.value) outputsList; }) // passthru;

      outputToAttrListElement = outputName:
        { name = outputName;
          value = commonAttrs // {
            inherit (drv.${outputName}) type outputName;
            drvPath = assert condition; drv.${outputName}.drvPath;
            outPath = assert condition; drv.${outputName}.outPath;
          };
        };

      outputsList = map outputToAttrListElement outputs;
    in commonAttrs // {
      outputUnspecified = true;
      drvPath = assert condition; drv.drvPath;
      outPath = assert condition; drv.outPath;
    };

  /* Strip a derivation of all non-essential attributes, returning
     only those needed by hydra-eval-jobs. Also strictly evaluate the
     result to ensure that there are no thunks kept alive to prevent
     garbage collection. */
  hydraJob = drv:
    let
      outputs = drv.outputs or ["out"];

      commonAttrs =
        { inherit (drv) name system meta; inherit outputs; }
        // lib.optionalAttrs (drv._hydraAggregate or false) {
          _hydraAggregate = true;
          constituents = map hydraJob (lib.flatten drv.constituents);
        }
        // (lib.listToAttrs outputsList);

      makeOutput = outputName:
        let output = drv.${outputName}; in
        { name = outputName;
          value = commonAttrs // {
            outPath = output.outPath;
            drvPath = output.drvPath;
            type = "derivation";
            inherit outputName;
          };
        };

      outputsList = map makeOutput outputs;

      drv' = (lib.head outputsList).value;
    in lib.deepSeq drv' drv';

  /* Make a set of packages with a common scope. All packages called
     with the provided `callPackage' will be evaluated with the same
     arguments. Any package in the set may depend on any other. The
     `overrideScope'` function allows subsequent modification of the package
     set in a consistent way, i.e. all packages in the set will be
     called with the overridden packages. The package sets may be
     hierarchical: the packages in the set are called with the scope
     provided by `newScope' and the set provides a `newScope' attribute
     which can form the parent scope for later package sets. */
  makeScope = newScope: f:
    let self = f self // {
          newScope = scope: newScope (self // scope);
          callPackage = self.newScope {};
          overrideScope = g: lib.warn
            "`overrideScope` (from `lib.makeScope`) is deprecated. Do `overrideScope' (self: super: { … })` instead of `overrideScope (super: self: { … })`. All other overrides have the parameters in that order, including other definitions of `overrideScope`. This was the only definition violating the pattern."
            (makeScope newScope (lib.fixedPoints.extends (lib.flip g) f));
          overrideScope' = g: makeScope newScope (lib.fixedPoints.extends g f);
          packages = f;
        };
    in self;

  /* Like the above, but aims to support cross compilation. It's still ugly, but
     hopefully it helps a little bit. */
  makeScopeWithSplicing = splicePackages: newScope: otherSplices: keep: f:
    let
      spliced = splicePackages {
        pkgsBuildBuild = otherSplices.selfBuildBuild;
        pkgsBuildHost = otherSplices.selfBuildHost;
        pkgsBuildTarget = otherSplices.selfBuildTarget;
        pkgsHostHost = otherSplices.selfHostHost;
        pkgsHostTarget = self; # Not `otherSplices.selfHostTarget`;
        pkgsTargetTarget = otherSplices.selfTargetTarget;
      } // keep self;
      self = f self // {
        newScope = scope: newScope (spliced // scope);
        callPackage = newScope spliced; # == self.newScope {};
        # N.B. the other stages of the package set spliced in are *not*
        # overridden.
        overrideScope = g: makeScopeWithSplicing
          splicePackages
          newScope
          otherSplices
          keep
          (lib.fixedPoints.extends g f);
        packages = f;
      };
    in self;

}
