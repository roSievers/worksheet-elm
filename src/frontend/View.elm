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
        , Components.list
            (sheetListExerciseView model sheet)
            sheet.list
        ]
        (sheetSummarySidebar model sheet)


sheetListExerciseView : Model -> ExerciseSheet -> Exercise -> Html Msg
sheetListExerciseView model sheet exercise =
    case editVersion model exercise of
        Nothing ->
            exerciseView
                (if model.editMode then
                    toolboxDecorator sheet
                 else
                    emptyDecorator
                )
                exercise

        Just edit ->
            exerciseEditView edit


exerciseEditView : Exercise -> Html Msg
exerciseEditView exercise =
    div [ class "summary" ]
        [ div []
            [ input
                [ type' "text"
                , placeholder "Title"
                , onInput (ExerciseEditor << UpdateTitle)
                , value exercise.title
                , class "edit-h1"
                ]
                []
            , textarea
                [ placeholder "Text"
                , onInput (ExerciseEditor << UpdateText)
                , value exercise.text
                , class "edit-p"
                ]
                []
            , div [ class "right-align" ]
                [ button [ onClick CancelEdit ] [ text "Cancel" ]
                , button [ onClick (SheetMessage (UpdateExercise exercise))] [ text "Save" ]
                ]
            ]
        ]


editVersion : Model -> Exercise -> Maybe Exercise
editVersion model exercise =
    case model.edit of
        Nothing ->
            Nothing

        Just edit ->
            if edit.uid == exercise.uid then
                Just edit
            else
                Nothing


{-| This decorator assumes that all exercises are part of the sheet and only
generates remove buttons. It is meant to be used on the sheet view only.
-}
toolboxDecorator : ExerciseSheet -> Decorator Exercise
toolboxDecorator sheet exercise =
    span []
        [ button [ onClick (EditExercise exercise) ] [ Fa.edit |> large |> icon ]
        , button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)) ] [ Fa.close |> large |> icon ]
        ]


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
        , Components.list
            (exerciseView
                (model.sheet
                    |> Maybe.map addRemoveDecorator
                    |> Maybe.withDefault emptyDecorator
                )
            )
            model.exercises
        ]


exerciseView : Decorator Exercise -> Exercise -> Html Msg
exerciseView decorator exercise =
    div [ class "summary" ]
        [ div []
            [ h1 [] [ text (exercise.title) ]
            , span [ class "summary-hints" ]
                [ decorator exercise
                ]
            , p [ class "summary-text" ] [ text exercise.text ]
            ]
        ]


sheetSummarySidebar : Model -> ExerciseSheet -> List (Html Msg)
sheetSummarySidebar model sheet =
    [ p []
        [ button [ onClick (SetEditMode True), disableIf (not model.editMode) ]
            [ Fa.pencil |> fixWidth |> icon, text " edit mode" ]
        , br [] []
        , button [ onClick (SetEditMode False), disableIf model.editMode ]
            [ Fa.eye |> fixWidth |> icon, text " view mode" ]
        ]
    , p []
        [ syncState sheet
        , br [] []
        , syncTime sheet
        ]
    , h3 [] [ text "Debug Info" ]
    , p []
        [ text ("edit: " ++ (toString model.edit))
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
                , text " Modified"
                ]

        ReadyToSync ->
            span []
                [ icon Fa.floppy_o
                , text " Modified"
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
            text "Original Version"

        Just time ->
            text
                ("Last Save: "
                    ++ toString (truncate (Time.inHours time) % 24)
                    ++ ":"
                    ++ toString (truncate (Time.inMinutes time) % 60)
                )


disableIf : Bool -> Html.Attribute msg
disableIf condition =
    if condition then
        class "disabled"
    else
        class ""


illegalRoute : Html Msg
illegalRoute =
    text "Error: This Page should not exist."
