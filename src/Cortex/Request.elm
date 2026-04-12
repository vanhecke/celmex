module Cortex.Request exposing
    ( Request
    , get
    , map
    , post
    , toInternal
    , withQuery
    )

import Json.Decode exposing (Decoder)
import Json.Encode as Encode


type Request a
    = Request
        { method : String
        , path : List String
        , query : List ( String, String )
        , body : Encode.Value
        , decoder : Decoder a
        }


get : List String -> Decoder a -> Request a
get path decoder =
    Request
        { method = "GET"
        , path = path
        , query = []
        , body = Encode.null
        , decoder = decoder
        }


post : List String -> Encode.Value -> Decoder a -> Request a
post path body decoder =
    Request
        { method = "POST"
        , path = path
        , query = []
        , body = body
        , decoder = decoder
        }


withQuery : List ( String, String ) -> Request a -> Request a
withQuery params (Request r) =
    Request { r | query = r.query ++ params }


map : (a -> b) -> Request a -> Request b
map f (Request r) =
    Request
        { method = r.method
        , path = r.path
        , query = r.query
        , body = r.body
        , decoder = Json.Decode.map f r.decoder
        }


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
