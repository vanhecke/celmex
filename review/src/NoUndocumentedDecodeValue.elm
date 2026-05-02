module NoUndocumentedDecodeValue exposing (rule)

{-| Forbids `Json.Decode.value` references that are not justified by an
adjacent `{- Decoder escape: <reason> -}` block comment.

@docs rule

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.ModuleNameLookupTable as Lookup exposing (ModuleNameLookupTable)
import Review.Rule as Rule exposing (Rule)


type alias Context =
    { lookupTable : ModuleNameLookupTable
    , escapeMarkers : List Range
    }


{-| `Decode.value` is the SDK's last-resort escape hatch for genuinely
free-form maps, polymorphic shapes, and raw byte streams. Every use must
be justified by an adjacent `{- Decoder escape: <reason> -}` block
comment so contributors can `grep -rn "Decoder escape:"` for a complete
catalog of typing gaps. See CLAUDE.md for the contract.
-}
rule : Rule
rule =
    Rule.newModuleRuleSchemaUsingContextCreator "NoUndocumentedDecodeValue" initContext
        |> Rule.withCommentsVisitor commentsVisitor
        |> Rule.withExpressionEnterVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


initContext : Rule.ContextCreator () Context
initContext =
    Rule.initContextCreator
        (\lookupTable () -> { lookupTable = lookupTable, escapeMarkers = [] })
        |> Rule.withModuleNameLookupTable


commentsVisitor : List (Node String) -> Context -> ( List (Rule.Error {}), Context )
commentsVisitor comments ctx =
    ( []
    , { ctx
        | escapeMarkers =
            comments
                |> List.filter (\node -> String.contains "Decoder escape:" (Node.value node))
                |> List.map Node.range
      }
    )


expressionVisitor : Node Expression -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor node ctx =
    case Node.value node of
        Expression.FunctionOrValue _ "value" ->
            case Lookup.moduleNameFor ctx.lookupTable node of
                Just [ "Json", "Decode" ] ->
                    if hasNearbyMarker (Node.range node) ctx.escapeMarkers then
                        ( [], ctx )

                    else
                        ( [ Rule.error
                                { message = "Decode.value used here without a 'Decoder escape:' justification."
                                , details =
                                    [ "Add a {- Decoder escape: <reason> -} block comment immediately above this call (or on the same line) explaining why the field cannot be typed."
                                    , "See CLAUDE.md for the contract and `grep -rn \"Decoder escape:\"` for current examples."
                                    ]
                                }
                                (Node.range node)
                          ]
                        , ctx
                        )

                _ ->
                    ( [], ctx )

        _ ->
            ( [], ctx )


hasNearbyMarker : Range -> List Range -> Bool
hasNearbyMarker callRange markers =
    {- A marker counts as adjacent if its end is on or above the call's
       start row, within 6 lines. elm-format will sometimes pull a marker
       a couple of lines above due to indentation/parenthesisation; the
       6-line window is conservative slack.
    -}
    List.any
        (\m ->
            let
                gap =
                    callRange.start.row - m.end.row
            in
            gap >= 0 && gap <= 6
        )
        markers
