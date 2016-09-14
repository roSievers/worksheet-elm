module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)

type Msg
    = UpdateTitle String
    | UpdateText String
    | CreateExercise
    | DeleteExercise Int
    | AddExercise Exercise
    | RemoveExercise Int
    | SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived (List Exercise)
