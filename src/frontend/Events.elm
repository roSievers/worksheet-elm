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
    | UpdateExercise Exercise
    | SwitchPosition Int Int


type EEditorMsg
    = UpdateTitle String
    | UpdateText String

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
    | EditExercise Exercise
    | CancelEdit
    | SetEditMode Bool

type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
