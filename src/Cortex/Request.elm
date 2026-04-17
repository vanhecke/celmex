module Cortex.Request exposing
    ( Request
    , get, post, postEmpty
    , map
    , toInternal
    )

{-| Opaque request descriptor. Each `Cortex.Api.*` module builds a
`Request a` describing the endpoint to hit and how to decode its response;
[`Cortex.Client.send`](Cortex-Client#send) is what actually dispatches it.

Only `GET` and `POST` are provided — the Cortex Advanced API does not use
`PUT`, `PATCH`, or `DELETE`, so adding those verbs would be dead code.

@docs Request
@docs get, post, postEmpty
@docs map
@docs toInternal

-}

import Json.Decode exposing (Decoder)
import Json.Encode as Encode


{-| A pending HTTP request paired with its response decoder. Opaque so the
wire format stays an implementation detail of the SDK.
-}
type Request a
    = Request
        { method : String
        , path : List String
        , query : List ( String, String )
        , body : Encode.Value
        , decoder : Decoder a
        }


{-| Build a GET request from a path (as a list of segments) and a response
decoder.
-}
get : List String -> Decoder a -> Request a
get path decoder =
    Request
        { method = "GET"
        , path = path
        , query = []
        , body = Encode.null
        , decoder = decoder
        }


{-| Build a POST request from a path, a JSON body, and a response decoder.
-}
post : List String -> Encode.Value -> Decoder a -> Request a
post path body decoder =
    Request
        { method = "POST"
        , path = path
        , query = []
        , body = body
        , decoder = decoder
        }


{-| POST with the empty advanced-API envelope `{"request_data": {}}` as the
body. Used by endpoints that take no filters or paging arguments.
-}
postEmpty : List String -> Decoder a -> Request a
postEmpty path decoder =
    post path (Encode.object [ ( "request_data", Encode.object [] ) ]) decoder


{-| Transform the decoded response value. Useful for wrapping a typed result
into a different shape before it reaches your `update`.
-}
map : (a -> b) -> Request a -> Request b
map f (Request r) =
    Request
        { method = r.method
        , path = r.path
        , query = r.query
        , body = r.body
        , decoder = Json.Decode.map f r.decoder
        }


{-| Extract the raw method/path/query/body/decoder record. Intended as an
escape hatch for [`Cortex.Client.toRequestRecord`](Cortex-Client#toRequestRecord)
and custom dispatchers; most consumers should not need this.
-}
toInternal :
    Request a
    ->
        { method : String
        , path : List String
        , query : List ( String, String )
        , body : Encode.Value
        , decoder : Decoder a
        }
toInternal (Request r) =
    r
