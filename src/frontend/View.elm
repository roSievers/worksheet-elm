module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style, id)
import Html.Events exposing (..)
import Time
import Components exposing (Decorator, IndexDecorator)
import Events exposing (..)
import Exercise exposing (Exercise)
import Sheet exposing (Sheet, LazySheet, SyncState(..))
import FontAwesome exposing (..)
import Icons as Fa
import Model exposing (Model)
import Route exposing (..)


-- VIEW


view : Model -> Html Msg
view model =
    case model.route of
        Search ->
            searchPanel model

        Current ->
            model.sheet
                |> Maybe.map (\sheet -> sheetPanel model sheet)
                |> Maybe.withDefault illegalRoute

        Home ->
            homePanel model


homePanel : Model -> Html Msg
homePanel model =
    Components.layout
        model
        [ h1 [] [ text "Welcome to Moni-Worksheet" ] ]
        (Components.mainFullWidth
            (case model.sheets of
                Nothing ->
                    [ p [] [ text "No Worksheets known." ]
                    ]

                Just sheets ->
                    List.append
                        [ p [] [ text "Choose an execise sheet to work on" ]
                        ]
                        (List.map loadSheetButton sheets)
            )
        )


loadSheetButton : LazySheet -> Html Msg
loadSheetButton lsheet =
    button [ onClick (SetSheet (Just lsheet)), class "pure-button" ] [ text lsheet.title ]


sheetPanel : Model -> Sheet -> Html Msg
sheetPanel model sheet =
    Components.layout
        model
        [ h1 [] [ text sheet.title ]
        , h2 [] [ button [ onClick (SetSheet Nothing), class "pure-button" ] [ text "Close" ] ]
        ]
        (Components.mainWithSidebar
            [ Components.list
                (sheetListExerciseView model sheet)
                sheet.list
            ]
            (sheetSummarySidebar model sheet)
        )


sheetListExerciseView : Model -> Sheet -> IndexDecorator Exercise
sheetListExerciseView model sheet index exercise =
    case editVersion model exercise of
        Nothing ->
            exerciseView
                (if model.editMode then
                    toolboxDecorator sheet
                 else
                    emptyDecorator
                )
                index
                exercise

        Just edit ->
            exerciseEditView index edit


exerciseEditView : IndexDecorator Exercise
exerciseEditView _ exercise =
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
                [ button [ onClick CancelEdit, class "pure-button" ] [ text "Cancel" ]
                , text " "
                , button [ onClick (SheetMessage (UpdateExercise exercise)), class "pure-button pure-button-primary" ] [ text "Save" ]
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
toolboxDecorator : Sheet -> IndexDecorator Exercise
toolboxDecorator sheet index exercise =
    span []
        [ button [ onClick (SheetMessage (SwitchPosition index (index - 1))), class "pure-button" ] [ icon Fa.arrow_up ]
        , button [ onClick (SheetMessage (SwitchPosition index (index + 1))), class "pure-button" ] [ icon Fa.arrow_down ]
        , button [ onClick (EditExercise exercise), class "pure-button" ] [ Fa.edit |> icon ]
        , button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)), class "pure-button" ] [ Fa.close |> icon ]
        ]


addRemoveDecorator : Sheet -> IndexDecorator Exercise
addRemoveDecorator sheet _ exercise =
    if Sheet.member exercise.uid sheet then
        button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)), class "pure-button" ] [ Fa.close |> icon ]
    else
        button [ onClick (ExerciseMessage (AddExercise exercise)), class "pure-button" ] [ Fa.plus |> icon ]


emptyDecorator : IndexDecorator Exercise
emptyDecorator _ _ =
    span [] []


searchPanel : Model -> Html Msg
searchPanel model =
    Components.layout
        model
        [ h1 [] [ text "All Exercises" ] ]
        (Components.mainFullWidth
            [ Components.list
                (exerciseView
                    (model.sheet
                        |> Maybe.map addRemoveDecorator
                        |> Maybe.withDefault emptyDecorator
                    )
                )
                model.exercises
            ]
        )


exerciseView : IndexDecorator Exercise -> IndexDecorator Exercise
exerciseView decorator index exercise =
    div [ class "summary" ]
        [ div [ class "exercise-view" ]
            [ div []
                [ h2 [ class "content-subhead" ]
                    [ text (exercise.title) ]
                , span [ class "exercise-buttons" ]
                    [ decorator index exercise
                    ]
                ]
            , p [ class "summary-text" ] [ text exercise.text ]
            ]
        , betweenMenu (addButton index)
        ]


betweenMenu : List (Html msg) -> Html msg
betweenMenu buttons =
    div [ class "between-menu" ] buttons


addButton : Int -> List (Html Msg)
addButton index =
    [ button [ class "pure-button" ] [ icon Fa.plus ]
    ]


sheetSummarySidebar : Model -> Sheet -> List (Html Msg)
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


syncState : Sheet -> Html Msg
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


syncTime : Sheet -> Html Msg
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
        class "pure-button wide-button"
    else
        class "pure-button wide-button pure-button-active"


illegalRoute : Html Msg
illegalRoute =
    text "Error: This Page should not exist."
