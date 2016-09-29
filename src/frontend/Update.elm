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
        ExerciseEditor msg' ->
            case model.edit of
                Just exercise ->
                    updateEEditor msg' model exercise

                Nothing ->
                    ( model, Cmd.none )

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
                    let
                        ( newSheet, command ) =
                            updateSheet msg sheet
                    in
                        ( { model
                            | sheet = Just newSheet
                          }
                        , command
                        )

        Save time sheet ->
            ( model
            , Task.perform LoadingFail (\_ -> SheetMessage (SaveDone time)) (Sheet.update sheet)
            )

        EditExercise exercise ->
            ( { model | edit = Just exercise }
            , Cmd.none
            )

        CancelEdit ->
            ( { model | edit = Nothing }
            , Cmd.none
            )

        SetEditMode bool ->
            ( { model | editMode = bool }
            , Cmd.none
            )


updateSheet : SheetMsg -> Sheet -> ( Sheet, Cmd Msg )
updateSheet msg sheet =
    case msg of
        NewExercise exercise ->
            ( Sheet.insert exercise sheet
            , Cmd.none
            )

        DirtySheet ->
            ( Sheet.dirty sheet
            , Cmd.none
            )

        AutosaveTick time ->
            let
                ( newSheet, doSave ) =
                    Sheet.autosaveTick sheet
            in
                ( newSheet
                , if doSave then
                    Cmd.Extra.message (Save time newSheet)
                  else
                    Cmd.none
                )

        SaveDone time ->
            ( Sheet.saveDone time sheet
            , Cmd.none
            )

        UpdateExercise exercise ->
            ( Sheet.insert exercise sheet
            , Cmd.batch
                [ Cmd.Extra.message CancelEdit
                , Task.perform LoadingFail (NewExercise >> SheetMessage) (Exercise.updateExercise exercise)
                ]
            )

        SwitchPosition first second ->
            ( Sheet.switchPosition first second sheet
            , Cmd.Extra.message (SheetMessage DirtySheet) )


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


updateEEditor : EEditorMsg -> Model -> Exercise -> ( Model, Cmd Msg )
updateEEditor msg model exercise =
    case msg of
        UpdateTitle title ->
            ( { model | edit = Just { exercise | title = title } }, Cmd.none )

        UpdateText text ->
            ( { model | edit = Just { exercise | text = text } }, Cmd.none )
