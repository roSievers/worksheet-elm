module Components exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.App as Html
import Html.Events exposing (..)
import Route exposing (..)
import Events exposing (..)


--renderHeader : Model -> Html Msg
renderHeader model =
    div []
        [ div [ style [ ( "background-color", "rgb(238, 238, 238)" ) ] ]
            [ div [ class "center", style [ ( "padding", "10px 0" ) ] ]
                [ button [ onClick (SetRoute Home) ] [ text "Home" ]
                , button [ onClick (SetRoute Sheet) ] [ text "Worksheet" ]
                , button [ onClick (SetRoute Search) ] [ text "Search" ]
                ]
            ]
        , div [ style [ ( "background-color", "rgb(96,181,204)" ) ] ]
            [ div [ style [ ( "width", "920px" ), ( "margin-left", "auto" ), ( "margin-right", "auto" ) ] ]
                [ div [ style [ ( "margin", "0" ), ( "padding", "1px 0" ) ] ] []
                ]
            ]
        ]
