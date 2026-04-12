port module Cli.Ports exposing (exit, stderr, stdout)


port stdout : String -> Cmd msg


port stderr : String -> Cmd msg


port exit : Int -> Cmd msg
