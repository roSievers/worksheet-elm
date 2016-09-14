module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)


type Msg
    = UpdateTitle String
    | UpdateText String
    | CreateExercise
    | SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived ExerciseSheet
    | ExerciseMessage ExerciseMsg
    | SheetListArrived (List LazySheet)
    | SetSheet LazySheet


type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
