module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.Events exposing (..)
import Components
import Events exposing (..)
import Exercise exposing (Exercise)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)
import FontAwesome exposing (..)
import Icons as Fa
import Model exposing (Model)
import Route exposing (..)

-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ Components.header model
        , case model.route of
            Search ->
                mainPanel model

            Current ->
                sheetPanel model

            Home ->
                homePanel model

            SingleExercise exercise ->
                singleExercise model exercise
        ]


singleExercise : Model -> Exercise -> Html Msg
singleExercise model exercise =
    Components.mainFullWidth
        [ input [ type' "text", placeholder "Title", onInput (ExerciseEditor << UpdateTitle), value exercise.title, class "edit-h1" ] []
        , textarea [ placeholder "Text", onInput (ExerciseEditor << UpdateText), value exercise.text, class "edit-p" ] []
        , br [] []
        , button [ onClick (ExerciseEditor CreateExercise) ] [ text "Add to List" ]
        ]


homePanel : Model -> Html Msg
homePanel model =
    Components.mainFullWidth
        (case model.sheets of
            Nothing ->
                [ h1 [] [ text "Welcome" ]
                , p [] [ text "No Worksheets known." ]
                ]

            Just sheets ->
                List.append
                    [ h1 [] [ text "Welcome" ]
                    , p [] [ text "Choose an execise sheet to work on" ]
                    ]
                    (List.map loadSheetButton sheets)
        )


loadSheetButton : LazySheet -> Html Msg
loadSheetButton lsheet =
    button [ onClick (SetSheet (Just lsheet)) ] [ text lsheet.title ]


sheetPanel : Model -> Html Msg
sheetPanel model =
    case model.sheet of
        Nothing ->
            Components.mainFullWidth
                [ h1 [] [ text "No Sheet selected." ]
                , button [ onClick (SetRoute Home) ] [ text "Return to landing Page." ]
                ]

        Just sheet' ->
            Components.mainWithSidebar
                [ h1 [] [ text sheet'.title ]
                , span [ class "summary-hints" ]
                    [ button [ onClick (SetSheet Nothing) ] [ text "Close" ]
                    ]
                , Components.exerciseList model.sheet (sheet'.list)
                ]
                (sheetSummarySidebar model)


mainPanel : Model -> Html Msg
mainPanel model =
    Components.mainFullWidth
        [ h1 [] [ text "All Exercises" ]
        , Components.exerciseList model.sheet model.exercises
        ]


sheetSummarySidebar : Model -> List (Html Msg)
sheetSummarySidebar model =
    [ h1 [] [ text "Overview" ]
    , case model.sheet of
        Nothing ->
            p [] []

        Just sheet' ->
            p []
                [ text "Count: "
                , sheet'
                    |> ExerciseSheet.length
                    |> toString
                    |> text
                ]
    ]
