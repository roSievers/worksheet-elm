module Events exposing (..)

import Http
import Route exposing (..)
import Exercise exposing (..)
import Sheet exposing (Sheet, LazySheet)

import Time exposing (Time)

{-| This type only contains messages where the update needs the SheetList
component to exist. -}
type SheetMsg
    = NewExercise Int Exercise
    | DirtySheet
    | AutosaveTick Time
    | SaveDone Time
    | UpdateExercise Exercise
    | SwitchPosition Int Int
    | InsertNewExercise Int
    | CutExercise Exercise
    | PasteExercise Int


type EEditorMsg
    = UpdateTitle String
    | UpdateText String

type Msg
    = ExerciseEditor EEditorMsg
    | SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived Sheet
    | SheetListArrived (List LazySheet)
    | ExerciseMessage ExerciseMsg
    | SetSheet (Maybe LazySheet)
    | SheetMessage SheetMsg
    | Save Time Sheet
    | EditExercise Exercise
    | CancelEdit
    | SetEditMode Bool
    | ToggleResponsiveMenu

type ExerciseMsg
    = AddExercise Exercise
    | RemoveExercise Int
