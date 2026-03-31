%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/"],
        excluded: [
          ~r"/proto/",
          "lib/cosmos/",
          "lib/cosmwasm/",
          "lib/tendermint/",
          "lib/thorchain/thorchain/"
        ]
      },
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Design.TagTODO, false}
        ]
      }
    }
  ]
}
