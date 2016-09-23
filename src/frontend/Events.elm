module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)

import Time exposing (Time)

{-| This type only contains messages where the update can only affect the SheetList
Component. -}
type SheetMsg
    = NewExercise Exercise
    | DirtySheet
    | AutosaveTick Time
    | SaveDone Time


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
    | SheetMessage SheetMsg
    | Save Time ExerciseSheet

type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
