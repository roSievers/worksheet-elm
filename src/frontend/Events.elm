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
    | AutosaveTick Time
    | SaveDone Time
    | UpdateExercise Exercise
    | SwitchPosition Int Int
    | InsertNewExercise Int
    | CutExercise Exercise
    | PasteExercise Int
    | UpdateEditTitle String
    | UpdateEditText String
    | EditExercise Exercise
    | CancelEdit
    | AddExercise Exercise
    | RemoveExercise Int

type Msg
    = SetRoute Route
    | LoadingFail Http.Error
    | SearchResultsArrived (List Exercise)
    | SheetArrived Sheet
    | SheetListArrived (List LazySheet)
    | SetSheet LazySheet
    | CloseSheet
    | SheetMessage SheetMsg
    | SetEditMode Bool
    | ToggleResponsiveMenu
