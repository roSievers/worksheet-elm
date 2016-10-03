module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class, type', placeholder, value, style, id)
import Html.Events exposing (..)
import Time
import Markdown
import Components exposing (Decorator, IndexDecorator)
import Events exposing (..)
import Exercise exposing (Exercise)
import Sheet exposing (Sheet, LazySheet, SyncState(..))
import FontAwesome
import FontAwesome.Icons as Fa
import FontAwesome.Modifiers as FaMod
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
    let
        listComponent =
            if model.editMode then
                Components.listIntersperse (interExerciseMenu model sheet)
            else
                Components.list
    in
        Components.layout
            model
            [ h1 [] [ text sheet.title ]
            , h2 [] [ button [ onClick (SetSheet Nothing), class "pure-button" ] [ text "Close" ] ]
            ]
            (Components.mainWithSidebar
                [ listComponent
                    (sheetListExerciseView model sheet)
                    sheet.list
                ]
                (sheetSummarySidebar model sheet)
            )


sheetListExerciseView : Model -> Sheet -> IndexDecorator Exercise
sheetListExerciseView model sheet index exercise =
    case editVersion model sheet exercise of
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
                , onInput (SheetMessage << UpdateEditTitle)
                , value exercise.title
                , class "edit-h1"
                ]
                []
            , textarea
                [ placeholder "Text"
                , onInput (SheetMessage << UpdateEditText)
                , value exercise.text
                , class "edit-p"
                ]
                []
            , div [ class "right-align" ]
                [ button [ onClick (SheetMessage CancelEdit), class "pure-button" ] [ text "Cancel" ]
                , text " "
                , button [ onClick (SheetMessage (UpdateExercise exercise)), class "pure-button pure-button-primary" ] [ text "Save" ]
                ]
            ]
        ]


editVersion : Model -> Sheet -> Exercise -> Maybe Exercise
editVersion model sheet exercise =
    case sheet.edit of
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
        [ button [ onClick (SheetMessage (SwitchPosition index (index - 1))), class "pure-button" ] [ FontAwesome.toHtml Fa.arrow_up ]
        , button [ onClick (SheetMessage (SwitchPosition index (index + 1))), class "pure-button" ] [ FontAwesome.toHtml Fa.arrow_down ]
        , button [ onClick (SheetMessage (CutExercise exercise)), class "pure-button" ] [ FontAwesome.toHtml Fa.cut ]
        , button [ onClick (SheetMessage (EditExercise exercise)), class "pure-button" ] [ Fa.edit |> FontAwesome.toHtml ]
        , button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)), class "pure-button" ] [ Fa.close |> FontAwesome.toHtml ]
        ]


addRemoveDecorator : Sheet -> IndexDecorator Exercise
addRemoveDecorator sheet _ exercise =
    if Sheet.member exercise.uid sheet then
        button [ onClick (ExerciseMessage (RemoveExercise exercise.uid)), class "pure-button" ] [ Fa.close |> FontAwesome.toHtml ]
    else
        button [ onClick (ExerciseMessage (AddExercise exercise)), class "pure-button" ] [ Fa.plus |> FontAwesome.toHtml ]


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
            , p [ class "summary-text" ] [ Markdown.toHtml [] exercise.text ]
            ]
        ]


interExerciseMenu : Model -> Sheet -> Int -> () -> Html Msg
interExerciseMenu model sheet index _ =
    [ addButton index (), pasteButton model sheet index () ]
        |> List.filterMap identity
        |> betweenMenu


betweenMenu : List (Html msg) -> Html msg
betweenMenu buttons =
    div [ class "between-menu" ] buttons


addButton : Int -> () -> Maybe (Html Msg)
addButton index _ =
    Just (button [ onClick (SheetMessage (InsertNewExercise index)), class "pure-button" ] [ FontAwesome.toHtml Fa.plus ])


pasteButton : Model -> Sheet -> Int -> () -> Maybe (Html Msg)
pasteButton model sheet index _ =
    Maybe.map
        (\_ -> button [ onClick (SheetMessage (PasteExercise index)), class "pure-button" ] [ FontAwesome.toHtml Fa.paste ])
        sheet.cut


sheetSummarySidebar : Model -> Sheet -> List (Html Msg)
sheetSummarySidebar model sheet =
    [ p []
        [ button [ onClick (SetEditMode True), disableIf (not model.editMode) ]
            [ Fa.pencil |> FaMod.fixWidth |> FontAwesome.toHtml, text " edit mode" ]
        , br [] []
        , button [ onClick (SetEditMode False), disableIf model.editMode ]
            [ Fa.eye |> FaMod.fixWidth |> FontAwesome.toHtml, text " view mode" ]
        ]
    , p []
        [ syncState sheet
        , br [] []
        , syncTime sheet
        ]
    , h3 [] [ text "Debug Info" ]
    , p []
        [ text ("edit: " ++ (toString sheet.edit))
        ]
    ]


syncState : Sheet -> Html Msg
syncState sheet =
    case sheet.syncState of
        UpToDate ->
            span []
                [ FontAwesome.toHtml Fa.check
                , text " Saved"
                ]

        Delayed ->
            span []
                [ FontAwesome.toHtml Fa.floppy_o
                , text " Modified"
                ]

        ReadyToSync ->
            span []
                [ FontAwesome.toHtml Fa.floppy_o
                , text " Modified"
                ]

        Syncing ->
            span []
                [ FontAwesome.toHtml (FaMod.spinning Fa.refresh)
                , text " Saving..."
                ]

        SyncingOutdated ->
            span []
                [ FontAwesome.toHtml (FaMod.spinning Fa.refresh)
                , text " Saving..."
                ]

        SyncError ->
            span []
                [ FontAwesome.toHtml Fa.exclamation
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
