module Main exposing (..)

import Html.App as Html
import Events exposing (Msg)
import Model exposing (Model, init)
import View exposing (view)
import Update exposing (update)


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
