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

import CognitiveComplexity
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDeprecated
import NoDuplicatePorts
import NoExposingEverything
import NoForbiddenWords
import NoImportingEverything
import NoInconsistentAliases
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoPrematureLetComputation
import NoRecursiveUpdate
import NoRedundantlyQualifiedType
import NoSimpleLetBody
import NoUnnecessaryTrailingUnderscore
import NoUnoptimizedRecursion
import NoUnsafePorts
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedPorts
import NoUselessSubscriptions
import Review.Rule as Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
        |> Rule.ignoreErrorsForFiles [ "../cli/src/Cli/Ports.elm" ]
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeExpose.rule
        |> Rule.ignoreErrorsForFiles [ "src/Cli/Main.elm" ]
    , NoConfusingPrefixOperator.rule
    , NoDeprecated.rule NoDeprecated.defaults
    , NoPrematureLetComputation.rule
    , Simplify.rule Simplify.defaults
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , CognitiveComplexity.rule 15
        |> Rule.ignoreErrorsForFiles [ "src/Cli/TestMain.elm" ]
    , NoUnoptimizedRecursion.rule (NoUnoptimizedRecursion.optOutWithComment "IGNORE TCO")
    , NoRedundantlyQualifiedType.rule
    , NoSimpleLetBody.rule
    , NoUnnecessaryTrailingUnderscore.rule
    , NoInconsistentAliases.config
        [ ( "Json.Decode", "Decode" )
        , ( "Json.Encode", "Encode" )
        , ( "Json.Decode.Pipeline", "Pipeline" )
        ]
        |> NoInconsistentAliases.rule
    , NoModuleOnExposedNames.rule
    , NoForbiddenWords.rule [ "TODO", "FIXME", "XXX", "HACK" ]
    , NoDuplicatePorts.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
        |> Rule.ignoreErrorsForFiles [ "src/Cli/Ports.elm" ]
    , NoUnusedPorts.rule
    , NoMissingSubscriptionsCall.rule
    , NoRecursiveUpdate.rule
    , NoUselessSubscriptions.rule
    ]
        |> List.map (Rule.ignoreErrorsForDirectories [ "../src" ])
