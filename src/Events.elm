module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)


type Msg
    = UpdateTitle String
    | UpdateText String
    | CreateExercise
    | SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived (List Exercise)
    | ExerciseMessage ExerciseMsg


type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
