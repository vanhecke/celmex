module Cli.Encode.AttackSurface exposing (encode)

import Cortex.Api.AttackSurface exposing (AttackSurfaceRule, RulesResponse)
import Json.Encode as Encode


encode : RulesResponse -> Encode.Value
encode r =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "total_count", Encode.int v )) r.totalCount
            , Maybe.map (\v -> ( "result_count", Encode.int v )) r.resultCount
            , Just ( "attack_surface_rules", Encode.list encodeRule r.attackSurfaceRules )
            ]
        )


encodeRule : AttackSurfaceRule -> Encode.Value
encodeRule rule =
    Encode.object
        (List.filterMap identity
            [ Maybe.map (\v -> ( "attack_surface_rule_name", Encode.string v )) rule.attackSurfaceRuleName
            , Maybe.map (\v -> ( "enabled_status", Encode.string v )) rule.enabledStatus
            , Maybe.map (\v -> ( "priority", Encode.string v )) rule.priority
            , Maybe.map (\v -> ( "description", Encode.string v )) rule.description
            , Maybe.map (\v -> ( "category", Encode.string v )) rule.category
            , Maybe.map (\v -> ( "attack_surface_rule_id", Encode.string v )) rule.attackSurfaceRuleId
            , Just ( "asm_alert_categories", Encode.list identity rule.asmAlertCategories )
            , Maybe.map (\v -> ( "created", Encode.int v )) rule.created
            ]
        )
