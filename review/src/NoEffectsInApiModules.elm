module NoEffectsInApiModules exposing (rule)

{-| Forbids `Cortex.Api.*` sub-API modules from importing effectful modules.

@docs rule

-}

import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Error, Rule)


{-| `Cortex.Api.*` modules are required to be pure: they describe `Request a`
values and never invoke effects directly. All effects flow through
`Cortex.Client.send` / `sendWith`. This rule enforces that contract by
forbidding imports of `Cortex.Client` and `Http` from any module under
`src/Cortex/Api/`.
-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoEffectsInApiModules" ()
        |> Rule.withImportVisitor importVisitor
        |> Rule.fromModuleRuleSchema
        |> Rule.filterErrorsForFiles isApiModule


isApiModule : String -> Bool
isApiModule path =
    String.startsWith "src/Cortex/Api/" path


forbidden : List ModuleName
forbidden =
    [ [ "Cortex", "Client" ]
    , [ "Http" ]
    , [ "Task" ]
    , [ "Process" ]
    , [ "Random" ]
    , [ "Time" ]
    ]


importVisitor : Node Import -> () -> ( List (Error {}), () )
importVisitor node () =
    let
        imported : ModuleName
        imported =
            node |> Node.value |> .moduleName |> Node.value
    in
    if List.member imported forbidden then
        ( [ Rule.error
                { message = "Cortex.Api.* modules must be pure"
                , details =
                    [ "This module imports " ++ String.join "." imported ++ ", but Cortex.Api.* sub-API modules are required to be pure (no effects, no HTTP)."
                    , "Return `Request a` here and let Cortex.Client.send / sendWith do the effect."
                    ]
                }
                (Node.range node)
          ]
        , ()
        )
    else
        ( [], () )
