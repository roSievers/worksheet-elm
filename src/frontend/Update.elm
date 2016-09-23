module Update exposing (update)

import Task
import Cmd.Extra
import Debug exposing (crash)
import Route exposing (..)
import Events exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)
import Model exposing (Model)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ExerciseEditor msg' ->
            updateEEditor msg' model

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
                    ( model, Task.perform LoadingFail SheetArrived <| ExerciseSheet.load lsheet' )

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
            , Task.perform LoadingFail (\_ -> SheetMessage (SaveDone time)) (ExerciseSheet.update sheet)
            )


updateSheet : SheetMsg -> ExerciseSheet -> ( ExerciseSheet, Cmd Msg )
updateSheet msg sheet =
    case msg of
        NewExercise exercise ->
            ( ExerciseSheet.insert exercise sheet
            , Cmd.none
            )

        DirtySheet ->
            ( ExerciseSheet.dirty sheet
            , Cmd.none
            )

        AutosaveTick time ->
            let
                ( newSheet, doSave ) =
                    ExerciseSheet.autosaveTick sheet
            in
                ( newSheet
                , if doSave then
                    Cmd.Extra.message (Save time newSheet)
                  else
                    Cmd.none
                )

        SaveDone time ->
            ( ExerciseSheet.saveDone time sheet
            , Cmd.none
            )


updateExercise : ExerciseMsg -> Model -> ( Model, Cmd Msg )
updateExercise msg model =
    case msg of
        AddExercise exercise ->
            ( { model
                | sheet = Maybe.map (ExerciseSheet.insert exercise) model.sheet
              }
            , Cmd.Extra.message (SheetMessage DirtySheet)
            )

        RemoveExercise uid ->
            ( { model
                | sheet = Maybe.map (ExerciseSheet.remove uid) model.sheet
              }
            , Cmd.Extra.message (SheetMessage DirtySheet)
            )


updateEEditor : EEditorMsg -> Model -> ( Model, Cmd Msg )
updateEEditor msg model =
    case model.route of
        SingleExercise exercise ->
            case msg of
                UpdateTitle title ->
                    ( { model | route = SingleExercise { exercise | title = title } }, Cmd.none )

                UpdateText text ->
                    ( { model | route = SingleExercise { exercise | text = text } }, Cmd.none )

                CreateExercise ->
                    ( { model | route = SingleExercise blankExercise }
                    , Task.perform LoadingFail (NewExercise >> SheetMessage) (Exercise.updateExercise exercise)
                    )

        _ ->
            ( model, Cmd.none )
