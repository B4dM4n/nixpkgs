with import ../default.nix;
let
  # unnamed overridables
  callableU = makeOverridable ({ foo }: { result = foo; });
  overridableU = callableU { foo = 1; };

  callableUU = makeOverridable ({ bar }: (callableU { foo = bar; }));
  overridableUU = callableUU { bar = 10; };

  # named overridables
  callableN = makeOverridableLayer "l1" ({ foo }: { result = foo; });
  overridableN = callableN { foo = 1; };

  callableNN = makeOverridableLayer "l2" ({ bar }: (callableN { foo = bar; }));
  overridableNN = callableNN { bar = 11; };

  # named + unnamed overridables
  callableNU = makeOverridable ({ baz }: (callableN { foo = baz; }));
  overridableNU = callableNU { baz = 12; };
  callableNUN = makeOverridableLayer "l2" ({ bar }: (callableNU { baz = bar; }));
  overridableNUN = callableNUN { bar = 13; };

  # unnamed + named overridables
  callableUN = makeOverridableLayer "l1" ({ bar }: (callableU { foo = bar; }));
  overridableUN = callableUN { bar = 14; };

  callableUNU = makeOverridable ({ baz }: (callableUN { bar = baz; }));
  overridableUNU = callableUNU { baz = 15; };

  mkSimpleTest = name: overridable: layers: topArg: input: {
    "test${name}" = {
      expr = overridable.result;
      expected = input;
    };

    "test${name}OverrideS" = {
      expr = (
        overridable.override { ${topArg} = 2; }
      ).result;
      expected = 2;
    };
    "test${name}OverrideF" = {
      expr = (
        overridable.override (old: { ${topArg} = old.${topArg} + 1; })
      ).result;
      expected = input + 1;
    };

    "test${name}OverrideAttrsS" = {
      expr = (
        overridable.overrideAttrs { foo = 2; }
      ).result;
      expected = 2;
    };
    "test${name}OverrideAttrsF" = {
      expr = (
        overridable.overrideAttrs (old: { foo = old.foo + 1; })
      ).result;
      expected = input + 1;
    };

    "test${name}OverrideLayerNameNotFound" = {
      expr =
        builtins.tryEval (
          (
            overridable.overrideLayerName "no-exist" { rest = 2; }
          ).result
        );
      expected = { success = false; value = false; };
    };
    "test${name}OverrideLayersNotFoundS" = {
      expr =
        builtins.tryEval
          (
            overridable.overrideLayers { no-exist = { rest = 2; }; }
          ).result;
      expected = { success = false; value = false; };
    };
    "test${name}OverrideLayersRest" = {
      expr = {
        inherit (overridable.overrideLayers ((genList (_: { }) layers) ++ [{ rest = 2; }]))
          result __overrideLayers;
      };
      expected = { __overrideLayers = [{ rest = 2; }]; result = input; };
    };

    "test${name}OverrideSS" = {
      expr = (
        (overridable.override { ${topArg} = 2; }).override { ${topArg} = 4; }
      ).result;
      expected = 4;
    };
    "test${name}OverrideFF" = {
      expr = (
        (overridable.override (old: { ${topArg} = old.${topArg} + 1; })).override (old: { ${topArg} = old.${topArg} + 2; })
      ).result;
      expected = input + 3;
    };

    "test${name}OverrideSF" = {
      expr = (
        (overridable.override { ${topArg} = 2; }).override (old: { ${topArg} = old.${topArg} + 2; })
      ).result;
      expected = 4;
    };
    "test${name}OverrideFS" = {
      expr = (
        (overridable.override (old: { ${topArg} = old.${topArg} + 1; })).override { ${topArg} = 4; }
      ).result;
      expected = 4;
    };
  };

  mkLayer1Test = name: overridable: layers: layer1Arg: {
    "test${name}OverrideLayersL" = {
      expr = let r = overridable.overrideLayers [{ ${layer1Arg} = 2; }]; in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 2; hasLayers = false; };
    };
    "test${name}OverrideLayersS" = {
      expr = let r = overridable.overrideLayers { l1 = { ${layer1Arg} = 2; }; }; in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 2; hasLayers = false; };
    };
    "test${name}OverrideLayersLRest" = {
      expr = {
        inherit (overridable.overrideLayers (
          [{ ${layer1Arg} = 2; }] ++ (genList (_: { }) (layers - 1)) ++ [{ rest = 10; }]
        ))
          result __overrideLayers;
      };
      expected = { __overrideLayers = [{ rest = 10; }]; result = 2; };
    };
    "test${name}OverrideLayersSNotFound" = {
      expr =
        builtins.tryEval (
          (
            overridable.overrideLayerName "no-exist" { }
          ).result
        );
      expected = { success = false; value = false; };
    };
    "test${name}OverrideLayerName" = {
      expr = (
        overridable.overrideLayerName "l1" { ${layer1Arg} = 2; }
      ).result;
      expected = 2;
    };
    "test${name}OverrideLayerNameAttr" = {
      expr = (
        (overridable.overrideLayerName "l1" { ${layer1Arg} = 2; }).overrideAttrs (old: { foo = old.foo + 1; })
      ).result;
      expected = 3;
    };
  };

  mkLayer2Test = name: overridable: {
    "test${name}OverrideLayersL2" = {
      expr = let r = overridable.overrideLayers [{ foo = 2; } { bar = 5; }]; in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 2; hasLayers = false; };
    };
    "test${name}OverrideLayersS2" = {
      expr = let r = overridable.overrideLayers { l1 = { foo = 2; }; l2 = { bar = 5; }; }; in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 2; hasLayers = false; };
    };
    "test${name}OverrideLayersS2Attrs" = {
      expr = let r = (overridable.overrideLayers { l2 = { bar = 5; }; }).overrideAttrs (old: { foo = old.foo + 1; }); in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 6; hasLayers = false; };
    };
    "test${name}OverrideLayersS2Override" = {
      expr = let r = (overridable.overrideLayers { l2 = { bar = 5; }; }).override (old: { bar = old.bar + 2; }); in
        {
          inherit (r) result;
          hasLayers = r ? __overrideLayers;
        };
      expected = { result = 7; hasLayers = false; };
    };
  };
in
(mkSimpleTest "OverridableU" overridableU 0 "foo" 1) //
(mkSimpleTest "OverridableUU" overridableUU 0 "bar" 10) //
(mkSimpleTest "OverridableN" overridableN 1 "foo" 1) //
(mkSimpleTest "OverridableNN" overridableNN 2 "bar" 11) //
(mkSimpleTest "OverridableNU" overridableNU 1 "baz" 12) //
(mkSimpleTest "OverridableNUN" overridableNUN 2 "bar" 13) //
(mkSimpleTest "OverridableUN" overridableUN 1 "bar" 14) //
(mkSimpleTest "OverridableUNU" overridableUNU 1 "baz" 15) //

(mkLayer1Test "OverridableN" overridableN 1 "foo") //
(mkLayer1Test "OverridableNN" overridableNN 2 "foo") //
(mkLayer1Test "OverridableNUN" overridableNUN 2 "foo") //
(mkLayer1Test "OverridableUN" overridableUN 1 "bar") //
(mkLayer1Test "OverridableUNU" overridableUNU 1 "bar") //

(mkLayer2Test "OverridableNN" overridableNN) //
(mkLayer2Test "OverridableNUN" overridableNUN)
