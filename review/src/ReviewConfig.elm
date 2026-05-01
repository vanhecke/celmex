module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import Docs.NoMissing
import Docs.ReviewAtDocs
import Docs.ReviewLinksAndSections
import Docs.UpToDateReadmeLinks
import NoConfusingPrefixOperator
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDeprecated
import NoEffectsInApiModules
import NoExposingEverything
import NoImportingEverything
import NoMissingTypeAnnotation
import NoMissingTypeExpose
import NoPrematureLetComputation
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUrlStringConcatenation
import Review.Rule exposing (Rule)
import Simplify


config : List Rule
config =
    [ NoUrlStringConcatenation.rule
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnused.Variables.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeExpose.rule
    , NoConfusingPrefixOperator.rule
    , NoDeprecated.rule NoDeprecated.defaults
    , NoPrematureLetComputation.rule
    , Simplify.rule Simplify.defaults
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoEffectsInApiModules.rule
    , Docs.ReviewAtDocs.rule
    , Docs.NoMissing.rule
        { document = Docs.NoMissing.onlyExposed
        , from = Docs.NoMissing.exposedModules
        }
    , Docs.ReviewLinksAndSections.rule
    , Docs.UpToDateReadmeLinks.rule
    ]
