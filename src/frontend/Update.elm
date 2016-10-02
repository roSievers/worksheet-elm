module Update exposing (update)

import Task
import Cmd.Extra
import Debug exposing (crash)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import Sheet exposing (Sheet, LazySheet)
import Model exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetRoute route ->
            ( { model
                | route = route
              }
            , Cmd.none
            )

        LoadingFail err ->
            crash "LoadingFail"

        SearchResultsArrived new ->
            ( { model
                | exercises = List.append model.exercises new
              }
            , Cmd.none
            )

        SheetArrived new ->
            ( { model
                | sheet = Just new
              }
            , Cmd.none
            )

        ExerciseMessage msg' ->
            updateExercise msg' model

        SheetListArrived sheets ->
            ( { model
                | sheets = Just sheets
              }
            , Cmd.none
            )

        SetSheet lsheet ->
            case lsheet of
                Nothing ->
                    ( { model
                        | sheet = Nothing
                      }
                    , if model.route == Current then
                        Cmd.Extra.message (SetRoute Home)
                      else
                        Cmd.none
                    )

                Just lsheet' ->
                    ( model, Task.perform LoadingFail SheetArrived <| Sheet.load lsheet' )

        SheetMessage msg ->
            case model.sheet of
                Nothing ->
                    ( model, Cmd.none )

                Just sheet ->
                    updateSheet msg model sheet

        Save time sheet ->
            ( model
            , Task.perform LoadingFail (\_ -> SheetMessage (SaveDone time)) (Sheet.update sheet)
            )

        SetEditMode bool ->
            ( { model | editMode = bool }
            , Cmd.none
            )

        ToggleResponsiveMenu ->
            ( { model | responsiveMenuActive = not model.responsiveMenuActive }
            , Cmd.none
            )


{-| This could be refactored using optics.
-}
setSheet : ( Sheet, a ) -> Model -> ( Model, a )
setSheet ( sheet, cmd ) model =
    ( { model | sheet = Just sheet }, cmd )


updateSheet : SheetMsg -> Model -> Sheet -> ( Model, Cmd Msg )
updateSheet msg model sheet =
    case msg of
        NewExercise oldUID exercise ->
            setSheet
                ( Sheet.replaceOldUID oldUID exercise sheet
                , Cmd.Extra.message (SheetMessage DirtySheet)
                )
                model

        DirtySheet ->
            setSheet
                ( Sheet.dirty sheet
                , Cmd.none
                )
                model

        AutosaveTick time ->
            let
                ( newSheet, doSave ) =
                    Sheet.autosaveTick sheet
            in
                setSheet
                    ( newSheet
                    , if doSave then
                        Cmd.Extra.message (Save time newSheet)
                      else
                        Cmd.none
                    )
                    model

        SaveDone time ->
            setSheet
                ( Sheet.saveDone time sheet
                , Cmd.none
                )
                model

        UpdateExercise exercise ->
            setSheet
                ( Sheet.insert (Debug.log "exercise: " exercise) sheet
                , Cmd.batch
                    [ Cmd.Extra.message (SheetMessage CancelEdit)
                    , Task.perform LoadingFail
                        (NewExercise exercise.uid >> SheetMessage)
                        (Exercise.updateExercise exercise)
                    ]
                )
                model

        SwitchPosition first second ->
            setSheet
                ( Sheet.switchPosition first second sheet
                , Cmd.Extra.message (SheetMessage DirtySheet)
                )
                model

        InsertNewExercise index ->
            let
                ( newModel, uid ) =
                    Model.getEphemeralUID model
            in
                setSheet
                    ( Sheet.insertAt index (Exercise.buildExercise "" "" uid) sheet
                    , Cmd.none
                    )
                    newModel

        CutExercise exercise ->
            setSheet
                ( { sheet | cut = Just exercise }
                , Cmd.none
                )
                model

        PasteExercise index ->
            case sheet.cut of
                Nothing ->
                    ( model, Cmd.none )

                Just exercise ->
                    let
                        newSheet =
                            { sheet | cut = Nothing }
                                |> Sheet.insertAt index exercise
                    in
                        ( { model
                            | sheet = Just newSheet
                          }
                        , Cmd.Extra.message (SheetMessage DirtySheet)
                        )

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
            setSheet
                ( { sheet | edit = Just exercise }
                , Cmd.none
                )
                model

        CancelEdit ->
            setSheet
                ( { sheet | edit = Nothing }
                , Cmd.none
                )
                model


updateExercise : ExerciseMsg -> Model -> ( Model, Cmd Msg )
updateExercise msg model =
    case msg of
        AddExercise exercise ->
            ( { model
                | sheet = Maybe.map (Sheet.insert exercise) model.sheet
              }
            , Cmd.Extra.message (SheetMessage DirtySheet)
            )

        RemoveExercise uid ->
            ( { model
                | sheet = Maybe.map (Sheet.remove uid) model.sheet
              }
            , Cmd.Extra.message (SheetMessage DirtySheet)
            )
