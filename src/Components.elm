module Components exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.App as Html
import Html.Events exposing (..)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet)

--Header : Model -> Html Msg
header model =
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


exerciseList : ExerciseSheet -> List Exercise -> Html Msg
exerciseList sheet exercises =
    div [ class "catalog" ] <| List.map (exerciseListItem sheet) exercises


exerciseListItem : ExerciseSheet -> Exercise -> Html Msg
exerciseListItem sheet exercise =
    div [ class "summary" ]
        [ div []
            [ h1 [] [ text (exercise.title) ]
            , span [ class "summary-hints" ]
                [ if ExerciseSheet.member exercise.uid sheet then
                    button [ onClick (RemoveExercise exercise.uid) ] [ text "Remove Exercise" ]
                  else
                    button [ onClick (AddExercise exercise) ] [ text "Add Exercise" ]
                , button [ onClick (DeleteExercise exercise.uid) ] [ text "delete" ]
                ]
            , p [ class "summary-text" ] [ text exercise.text ]
            ]
        ]
