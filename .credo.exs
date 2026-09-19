%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/"],
        # Everything outside `lib/rujira` is generated protobuf code. It is not
        # hand-written and is regenerated wholesale, so linting it is noise.
        excluded: [
          ~r"\.pb\.ex$",
          "lib/cosmos/",
          "lib/cosmwasm/",
          "lib/tendermint/",
          "lib/thorchain/"
        ]
      },
      checks: %{
        # `disabled:` keeps every other default check enabled. Do not switch this
        # to `enabled:` — that *replaces* the check list, which silently reduced
        # this config to running zero checks.
        disabled: [
          # The TODOs in this codebase are deliberate trackers that name the
          # condition for their own removal, not lint debt.
          {Credo.Check.Design.TagTODO, []}
        ]
      }
    }
  ]
}
