module Model exposing (..)

import Task
import Events exposing (..)
import Exercise exposing (Exercise)
import ExerciseSheet exposing (ExerciseSheet, LazySheet)
import Requests exposing (requestExerciseList)
import Route exposing (Route(Home))


-- MODEL


type alias Model =
    { route : Route
    , exercises : List Exercise
    , sheet : Maybe ExerciseSheet
    , sheets : Maybe (List LazySheet)
    , currentUID : Int
    }


init : ( Model, Cmd Msg )
init =
    ( { route = Home
      , exercises = []
      , sheet = Nothing
      , sheets = Nothing
      , currentUID = 1001
      }
    , Cmd.batch
        [ requestExerciseList SearchResultsArrived "./data/search.json"
        , Task.perform LoadingFail SheetListArrived ExerciseSheet.loadSheetList
        ]
    )
