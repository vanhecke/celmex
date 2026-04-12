module Cli.Main exposing (main)

import Cli.Commands as Commands
import Cli.Ports as Ports
import Cortex.Auth as Auth
import Cortex.Client as Client
import Json.Decode as Decode
import Platform


type alias Flags =
    { argv : List String
    , tenant : String
    , apiKeyId : String
    , apiKey : String
    , timestamp : Int
    , nonce : String
    }


type alias Model =
    ()


type Msg
    = CommandMsg Commands.Msg


main : Program Decode.Value Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Decode.Value -> ( Model, Cmd Msg )
init flagsValue =
    case Decode.decodeValue flagsDecoder flagsValue of
        Ok flags ->
            let
                config =
                    { tenant = flags.tenant
                    , credentials =
                        { apiKeyId = flags.apiKeyId
                        , apiKey = flags.apiKey
                        }
                    }

                stamp =
                    { timestamp = flags.timestamp
                    , nonce = flags.nonce
                    }
            in
            case Commands.dispatch stamp config flags.argv of
                Ok cmd ->
                    ( (), Cmd.map CommandMsg cmd )

                Err msg ->
                    ( ()
                    , Cmd.batch
                        [ Ports.stderr (msg ++ "\n")
                        , Ports.exit 1
                        ]
                    )

        Err err ->
            ( ()
            , Cmd.batch
                [ Ports.stderr ("Failed to decode flags: " ++ Decode.errorToString err ++ "\n")
                , Ports.exit 1
                ]
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CommandMsg cmdMsg ->
            ( model, Cmd.map CommandMsg (Commands.handleResult cmdMsg) )


flagsDecoder : Decode.Decoder Flags
flagsDecoder =
    Decode.map6 Flags
        (Decode.field "argv" (Decode.list Decode.string))
        (Decode.field "tenant" Decode.string)
        (Decode.field "apiKeyId" Decode.string)
        (Decode.field "apiKey" Decode.string)
        (Decode.field "timestamp" Decode.int)
        (Decode.field "nonce" Decode.string)
