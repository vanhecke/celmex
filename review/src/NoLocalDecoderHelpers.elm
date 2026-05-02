module NoLocalDecoderHelpers exposing (rule)

{-| Forbids local re-declarations of the shared decoder helpers exported
from `Cortex.Decode`.

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node)
import Review.Rule as Rule exposing (Rule)


type alias Context =
    { isCortexDecode : Bool }


reserved : List String
reserved =
    [ "optionalField", "optionalList", "reply", "andMap" ]


{-| `optionalField`, `optionalList`, `reply`, and `andMap` are shared
decoder primitives exposed from `Cortex.Decode`. Re-declaring them in
another module duplicates the canonical implementation and lets it drift.
This rule forbids such declarations everywhere except `Cortex.Decode`
itself.
-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoLocalDecoderHelpers" { isCortexDecode = False }
        |> Rule.withModuleDefinitionVisitor moduleDefVisitor
        |> Rule.withDeclarationEnterVisitor declVisitor
        |> Rule.fromModuleRuleSchema


moduleDefVisitor : Node Module -> Context -> ( List (Rule.Error {}), Context )
moduleDefVisitor node ctx =
    ( []
    , { ctx | isCortexDecode = Module.moduleName (Node.value node) == [ "Cortex", "Decode" ] }
    )


declVisitor : Node Declaration -> Context -> ( List (Rule.Error {}), Context )
declVisitor node ctx =
    if ctx.isCortexDecode then
        ( [], ctx )

    else
        case Node.value node of
            Declaration.FunctionDeclaration func ->
                let
                    nameNode =
                        func.declaration |> Node.value |> .name

                    name =
                        Node.value nameNode
                in
                if List.member name reserved then
                    ( [ Rule.error
                            { message = name ++ " is a shared decoder helper — import it from Cortex.Decode instead of redefining it locally."
                            , details =
                                [ "Local declarations of this helper duplicate the canonical implementation in Cortex.Decode and let it drift over time."
                                , "Add `" ++ name ++ "` to `import Cortex.Decode exposing (...)` and delete this declaration."
                                ]
                            }
                            (Node.range nameNode)
                      ]
                    , ctx
                    )

                else
                    ( [], ctx )

            _ ->
                ( [], ctx )
