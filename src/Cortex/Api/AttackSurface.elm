module Cortex.Api.AttackSurface exposing
    ( AttackSurfaceRule, RulesResponse
    , getRules
    )

{-| Cortex ASM (attack-surface management) rule configuration.

@docs AttackSurfaceRule, RulesResponse
@docs getRules

-}

import Cortex.Decode exposing (andMap, optionalField, optionalList, reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)


{-| Paginated envelope returned by [`getRules`](#getRules).
-}
type alias RulesResponse =
    { totalCount : Maybe Int
    , resultCount : Maybe Int
    , attackSurfaceRules : List AttackSurfaceRule
    }


{-| A single ASM rule row.
-}
type alias AttackSurfaceRule =
    { attackSurfaceRuleName : Maybe String
    , attackSurfaceRuleId : Maybe String
    , enabledStatus : Maybe String
    , priority : Maybe String
    , category : Maybe String
    , description : Maybe String
    , knowledgeBaseLink : Maybe String
    , remediationGuidance : Maybe String
    , created : Maybe Int
    , modified : Maybe Int
    , modifiedBy : Maybe String
    , asmAlertCategories : List String
    }


{-| POST /public\_api/v1/get\_attack\_surface\_rules

List configured ASM rules with their enabled status, priority, category,
remediation guidance, and the alert categories the rule emits into.

-}
getRules : Request RulesResponse
getRules =
    Request.postEmpty
        [ "public_api", "v1", "get_attack_surface_rules" ]
        (reply rulesResponseDecoder)



-- DECODERS


rulesResponseDecoder : Decoder RulesResponse
rulesResponseDecoder =
    Decode.map3 RulesResponse
        (Decode.maybe (Decode.field "total_count" Decode.int))
        (Decode.maybe (Decode.field "result_count" Decode.int))
        (Decode.oneOf
            [ Decode.field "attack_surface_rules" (Decode.list attackSurfaceRuleDecoder)
            , Decode.succeed []
            ]
        )


attackSurfaceRuleDecoder : Decoder AttackSurfaceRule
attackSurfaceRuleDecoder =
    Decode.succeed AttackSurfaceRule
        |> andMap (optionalField "attack_surface_rule_name" Decode.string)
        |> andMap (optionalField "attack_surface_rule_id" Decode.string)
        |> andMap (optionalField "enabled_status" Decode.string)
        |> andMap (optionalField "priority" Decode.string)
        |> andMap (optionalField "category" Decode.string)
        |> andMap (optionalField "description" Decode.string)
        |> andMap (optionalField "knowledge_base_link" Decode.string)
        |> andMap (optionalField "remediation_guidance" Decode.string)
        |> andMap (optionalField "created" Decode.int)
        |> andMap (optionalField "modified" Decode.int)
        |> andMap (optionalField "modified_by" Decode.string)
        |> andMap (optionalList "asm_alert_categories" Decode.string)
