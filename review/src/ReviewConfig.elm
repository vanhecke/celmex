module ReviewConfig exposing (config)

{-| Do not rename the ReviewConfig module or the config function, because
`elm-review` will look for these.

To add packages that contain rules, add them to this review project using

    `elm install author/packagename`

when inside the directory containing this file.

-}

import CognitiveComplexity
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
import NoForbiddenWords
import NoImportingEverything
import NoInconsistentAliases
import NoLocalDecoderHelpers
import NoMissingTypeAnnotation
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoPrematureLetComputation
import NoPrimitiveTypeAlias
import NoRedundantlyQualifiedType
import NoSimpleLetBody
import NoUndocumentedDecodeValue
import NoUnnecessaryTrailingUnderscore
import NoUnoptimizedRecursion
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUrlStringConcatenation
import Review.Rule as Rule exposing (Rule)
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
    , NoUndocumentedDecodeValue.rule
    , NoLocalDecoderHelpers.rule
    , CognitiveComplexity.rule 15
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
        |> Rule.ignoreErrorsForFiles [ "../README.md" ]
    , NoPrimitiveTypeAlias.rule
    , Docs.ReviewAtDocs.rule
    , Docs.NoMissing.rule
        { document = Docs.NoMissing.onlyExposed
        , from = Docs.NoMissing.exposedModules
        }
    , Docs.ReviewLinksAndSections.rule
    , Docs.UpToDateReadmeLinks.rule
    ]
