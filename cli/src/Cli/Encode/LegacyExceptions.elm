module Cli.Encode.LegacyExceptions exposing (encodeFetch, encodeModules)

import Cortex.Api.LegacyExceptions exposing (FetchResponse, Module)
import Json.Encode as Encode


encodeModules : List Module -> Encode.Value
encodeModules modules =
    Encode.list encodeModule modules


encodeModule : Module -> Encode.Value
encodeModule m =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "module_id", Encode.int v )) m.moduleId
            , Maybe.map (\v -> ( "pretty_name", Encode.string v )) m.prettyName
            , Maybe.map (\v -> ( "title", Encode.string v )) m.title
            , Maybe.map (\v -> ( "label", Encode.string v )) m.label
            , Maybe.map (\v -> ( "profile_type", Encode.string v )) m.profileType
            , Just ( "platforms", Encode.list Encode.string m.platforms )
            , Just ( "conditions_definition", m.conditionsDefinition )
            ]
        )


encodeFetch : FetchResponse -> Encode.Value
encodeFetch r =
    Encode.object
        (List.filterMap identity
            [ Just ( "DATA", Encode.list identity r.data )
            , Maybe.map (\v -> ( "FILTER_COUNT", Encode.int v )) r.filterCount
            , Maybe.map (\v -> ( "TOTAL_COUNT", Encode.int v )) r.totalCount
            ]
        )
