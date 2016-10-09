module Update exposing (update)

import Task
import Cmd.Extra
import Debug exposing (crash)
import Return exposing (Return)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import Sheet exposing (Sheet, LazySheet)
import Model exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetRoute route ->
            model
                |> setRoute route
                |> Return.singleton

        LoadingFail err ->
            crash "LoadingFail"

        SearchResultsArrived new ->
            Return.singleton
                { model
                    | exercises = List.append model.exercises new
                }

        SheetArrived new ->
            Return.singleton { model | sheet = Just new }

        SheetListArrived sheets ->
            Return.singleton { model | sheets = Just sheets }

        SetSheet lazySheet ->
            Return.return
                model
                (Task.perform LoadingFail SheetArrived (Sheet.load lazySheet))

        CloseSheet ->
            { model | sheet = Nothing }
                |> (if (model.route == Current) then
                        setRoute Home
                    else
                        identity
                   )
                |> Return.singleton

        SheetMessage msg ->
            case model.sheet of
                Nothing ->
                    Return.singleton model

                Just sheet ->
                    updateSheet msg model sheet

        SetEditMode bool ->
            Return.singleton { model | editMode = bool }

        ToggleResponsiveMenu ->
            Return.singleton { model | responsiveMenuActive = not model.responsiveMenuActive }


setRoute : Route -> Model -> Model
setRoute route model =
    { model | route = route }


wrapModel : Model -> Sheet -> Model
wrapModel model sheet =
    { model | sheet = Just sheet }


updateSheet : SheetMsg -> Model -> Sheet -> ( Model, Cmd Msg )
updateSheet msg model sheet =
    case msg of
        NewExercise oldUID exercise ->
            Sheet.replaceOldUID oldUID exercise sheet
                |> Sheet.dirty
                |> wrapModel model
                |> Return.singleton

        AutosaveTick time ->
            let
                ( newSheet, doSave ) =
                    Sheet.autosaveTick sheet
            in
                newSheet
                    |> wrapModel model
                    |> Return.singleton
                    |> (if doSave then
                            Return.command
                                (Task.perform LoadingFail (\_ -> SheetMessage (SaveDone time)) (Sheet.update sheet))
                        else
                            identity
                       )

        SaveDone time ->
            Sheet.saveDone time sheet
                |> wrapModel model
                |> Return.singleton

        UpdateExercise exercise ->
            Sheet.insert exercise sheet
                |> wrapModel model
                |> Return.singleton
                |> Return.command (Cmd.Extra.message (SheetMessage CancelEdit))
                |> Return.command
                    (Task.perform LoadingFail
                        (NewExercise exercise.uid >> SheetMessage)
                        (Exercise.updateExercise exercise)
                    )

        SwitchPosition first second ->
            Sheet.switchPosition first second sheet
                |> Sheet.dirty
                |> wrapModel model
                |> Return.singleton

        InsertNewExercise index ->
            let
                ( newModel, uid ) =
                    Model.getEphemeralUID model
            in
                Sheet.insertAt index (Exercise.buildExercise "" "" uid) sheet
                    |> wrapModel newModel
                    |> Return.singleton

        CutExercise exercise ->
            { sheet | cut = Just exercise }
                |> wrapModel model
                |> Return.singleton

        PasteExercise index ->
            case sheet.cut of
                Nothing ->
                    ( model, Cmd.none )

                Just exercise ->
                    { sheet | cut = Nothing }
                        |> Sheet.insertAt index exercise
                        |> Sheet.dirty
                        |> wrapModel model
                        |> Return.singleton

        UpdateEditTitle title ->
            case sheet.edit of
                Just exercise ->
                    ( { model | sheet = Just { sheet | edit = Just { exercise | title = title } } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        UpdateEditText text ->
            case sheet.edit of
                Just exercise ->
                    ( { model | sheet = Just { sheet | edit = Just { exercise | text = text } } }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        EditExercise exercise ->
            { sheet | edit = Just exercise }
                |> wrapModel model
                |> Return.singleton

        CancelEdit ->
            { sheet | edit = Nothing }
                |> wrapModel model
                |> Return.singleton

        AddExercise exercise ->
            Sheet.insert exercise sheet
                |> Sheet.dirty
                |> wrapModel model
                |> Return.singleton

        RemoveExercise uid ->
            Sheet.remove uid sheet
                |> Sheet.dirty
                |> wrapModel model
                |> Return.singleton
