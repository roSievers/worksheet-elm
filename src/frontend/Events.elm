module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)


type EEditorMsg
    = UpdateTitle String
    | UpdateText String
    | CreateExercise

type Msg
    = ExerciseEditor EEditorMsg
    | SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived ExerciseSheet
    | SheetListArrived (List LazySheet)
    | ExerciseMessage ExerciseMsg
    | SetSheet (Maybe LazySheet)
    | NewExercise Exercise


type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
