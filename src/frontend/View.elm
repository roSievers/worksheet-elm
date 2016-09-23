module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style)
import Html.Events exposing (..)
import Time
import Components exposing (Decorator)
import Events exposing (..)
import Exercise exposing (Exercise)
import ExerciseSheet exposing (ExerciseSheet, LazySheet, SyncState(..))
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
                searchPanel model

            Current ->
                model.sheet
                    |> Maybe.map (\sheet -> sheetPanel model sheet)
                    |> Maybe.withDefault illegalRoute

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


sheetPanel : Model -> ExerciseSheet -> Html Msg
sheetPanel model sheet =
    Components.mainWithSidebar
        [ h1 [] [ text sheet.title ]
        , span [ class "summary-hints" ]
            [ button [ onClick (SetSheet Nothing) ] [ text "Close" ]
            ]
        , Components.exerciseList (addRemoveDecorator sheet) (sheet.list)
        ]
        (sheetSummarySidebar model sheet)


addRemoveDecorator : ExerciseSheet -> Decorator Exercise
addRemoveDecorator sheet exercise =
    if ExerciseSheet.member exercise.uid sheet then
        button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)) ] [ Fa.close |> large |> icon ]
    else
        button [ onClick (ExerciseMessage (AddExercise exercise)) ] [ Fa.plus |> large |> icon ]


emptyDecorator : Decorator Exercise
emptyDecorator _ =
    span [] []


searchPanel : Model -> Html Msg
searchPanel model =
    Components.mainFullWidth
        [ h1 [] [ text "All Exercises" ]
        , Components.exerciseList
            (model.sheet
                |> Maybe.map addRemoveDecorator
                |> Maybe.withDefault emptyDecorator
            )
            model.exercises
        ]


sheetSummarySidebar : Model -> ExerciseSheet -> List (Html Msg)
sheetSummarySidebar model sheet =
    [ h3 [] [ text "Tools" ]
    , p []
        [ syncState sheet
        , br [] []
        , syncTime sheet
        , br [] []
        , text "Count: "
        , sheet
            |> ExerciseSheet.length
            |> toString
            |> text
        , br [] []
        ]
    ]


syncState : ExerciseSheet -> Html Msg
syncState sheet =
    case sheet.syncState of
        UpToDate ->
            span []
                [ icon Fa.check
                , text " Saved"
                ]

        Delayed ->
            span []
                [ icon Fa.floppy_o
                , text " Unsaved Changes"
                ]

        ReadyToSync ->
            span []
                [ icon Fa.floppy_o
                , text " Unsaved Changes"
                ]

        Syncing ->
            span []
                [ icon (spinning Fa.refresh)
                , text " Saving..."
                ]

        SyncingOutdated ->
            span []
                [ icon (spinning Fa.refresh)
                , text " Saving..."
                ]

        SyncError ->
            span []
                [ icon Fa.exclamation
                , text " Error while saving."
                ]


syncTime : ExerciseSheet -> Html Msg
syncTime sheet =
    case sheet.lastSave of
        Nothing ->
            text "Unmodified"

        Just time ->
            text ("Last Save: "
              ++ toString (truncate (Time.inHours time) % 24)
              ++ ":"
              ++ toString (truncate (Time.inMinutes time) % 60)
              )


illegalRoute : Html Msg
illegalRoute =
    text "Error: This Page should not exist."
