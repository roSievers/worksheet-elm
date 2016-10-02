module Model exposing (..)

import Task
import Events exposing (..)
import Exercise exposing (Exercise)
import Sheet exposing (Sheet, LazySheet)
import Requests exposing (requestExerciseList)
import Route exposing (Route(Home))


-- MODEL


type alias Model =
    { route : Route
    , exercises : List Exercise
    , editMode : Bool
    , sheet : Maybe Sheet
    , sheets : Maybe (List LazySheet)
    , ephemeralUID : Int
    , responsiveMenuActive : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { route = Home
      , exercises = []
      , editMode = True
      , sheet = Nothing
      , sheets = Nothing
      , ephemeralUID = -1
      , responsiveMenuActive = False
      }
    , Cmd.batch
        [ requestExerciseList SearchResultsArrived "http://localhost:8010/api/deprecated/exercises"
        , Task.perform LoadingFail SheetListArrived Sheet.loadSheetList
        ]
    )


getEphemeralUID : Model -> ( Model, Int )
getEphemeralUID model =
    ( { model | ephemeralUID = model.ephemeralUID - 1 }
    , model.ephemeralUID
    )
