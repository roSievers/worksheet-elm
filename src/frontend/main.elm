module Main exposing (..)

import Html.App as Html
import Time
import Events exposing (Msg(SheetMessage), SheetMsg(AutosaveTick))
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
    Time.every (3*Time.second) (\_ -> SheetMessage AutosaveTick)
