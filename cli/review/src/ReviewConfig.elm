module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

This config is for the CLI application (`cli/`). The CLI's elm.json includes
`../src` in its source-directories, so review would otherwise re-analyze the
SDK package — those files are already covered by `/review/`. We use
`Rule.ignoreErrorsForDirectories ["../src"]` on every rule to scope this
config to `cli/src/` only.

-}

import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDeprecated
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoPrematureLetComputation
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingTypeAnnotation.rule
    , NoConfusingPrefixOperator.rule
    , NoDeprecated.rule NoDeprecated.defaults
    , NoPrematureLetComputation.rule
    , Simplify.rule Simplify.defaults
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    ]
        |> List.map (Rule.ignoreErrorsForDirectories [ "../src" ])
