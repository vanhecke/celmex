module Cortex.Api.AttackSurface exposing
    ( AttackSurfaceRule, RulesResponse
    , getRules
    )

{-| Cortex ASM (attack-surface management) rule configuration.

@docs AttackSurfaceRule, RulesResponse
@docs getRules

-}

import Cortex.Decode exposing (reply)
import Cortex.Request as Request exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


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
    , enabledStatus : Maybe String
    , priority : Maybe String
    , description : Maybe String
    , category : Maybe String
    , attackSurfaceRuleId : Maybe String
    , asmAlertCategories : List Encode.Value
    , created : Maybe Int
    }


{-| POST /public\_api/v1/get\_attack\_surface\_rules
-}
getRules : Request RulesResponse
getRules =
    Request.postEmpty
        [ "public_api", "v1", "get_attack_surface_rules" ]
        (reply rulesResponseDecoder)


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
    Decode.map8 AttackSurfaceRule
        (Decode.maybe (Decode.field "attack_surface_rule_name" Decode.string))
        (Decode.maybe (Decode.field "enabled_status" Decode.string))
        (Decode.maybe (Decode.field "priority" Decode.string))
        (Decode.maybe (Decode.field "description" Decode.string))
        (Decode.maybe (Decode.field "category" Decode.string))
        (Decode.maybe (Decode.field "attack_surface_rule_id" Decode.string))
        (Decode.oneOf
            [ Decode.field "asm_alert_categories" (Decode.list Decode.value)
            , Decode.succeed []
            ]
        )
        (Decode.maybe (Decode.field "created" Decode.int))
