module Components exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.App as Html
import Html.Events exposing (..)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet)
import FontAwesome exposing (..)
import Icons as Fa


type alias Decorator a = a -> Html Msg


{-| header : Model -> Html Msg
-}
header model =
    div []
        [ div [ style [ ( "background-color", "rgb(238, 238, 238)" ) ] ]
            [ div [ class "center", style [ ( "padding", "10px 0" ) ] ]
                [ button [ onClick (SetRoute Home) ] [ text " Home" ]
                , currentSheetButton model.sheet
                , button [ onClick (SetRoute Search) ] [ icon Fa.search, text " Search" ]
                ]
            ]
        , div [ style [ ( "background-color", "rgb(96,181,204)" ) ] ]
            [ div [ style [ ( "width", "920px" ), ( "margin-left", "auto" ), ( "margin-right", "auto" ) ] ]
                [ div [ style [ ( "margin", "0" ), ( "padding", "1px 0" ) ] ] []
                ]
            ]
        ]


currentSheetButton : Maybe ExerciseSheet -> Html Msg
currentSheetButton sheet =
    case sheet of
        Nothing ->
            span [] []

        Just sheet' ->
            button [ onClick (SetRoute Current) ] [ icon Fa.list, text " ", text sheet'.title ]


mainWithSidebar : List (Html msg) -> List (Html msg) -> Html msg
mainWithSidebar main sidebar =
    div [ class "center" ]
        [ div [ class "main-pannel" ]
            main
        , div [ class "Sidebar" ]
            sidebar
        ]


mainFullWidth : List (Html msg) -> Html msg
mainFullWidth main =
    div [ class "center" ]
        main


exerciseList : Decorator Exercise -> List Exercise -> Html Msg
exerciseList decorator exercises =
    div [ class "catalog" ] <|
        List.map (exerciseListItem decorator) exercises


exerciseListItem : Decorator Exercise -> Exercise -> Html Msg
exerciseListItem decorator exercise =
    div [ class "summary" ]
        [ div []
            [ h1 [ onClick (SetRoute (SingleExercise exercise)) ] [ text (exercise.title) ]
            , span [ class "summary-hints" ]
                [ decorator exercise
                ]
            , p [ class "summary-text" ] [ text exercise.text ]
            ]
        ]
