module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)

type Msg
    = UpdateTitle String
    | UpdateText String
    | CreateExercise
    | DeleteExercise Int
    | AddExercise Int
    | RemoveExercise Int
    | SetRoute Route
    | LoadingFail Http.Error
    | LoadingDone (List Exercise)
