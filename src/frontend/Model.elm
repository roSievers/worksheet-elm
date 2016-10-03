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
    -- The search Panel
    , exercises : List Exercise
    -- The list of all sheets, choose one to open.
    , sheets : Maybe (List LazySheet)
    , responsiveMenuActive : Bool
    , sheet : Maybe Sheet
    -- This will be removed once I have a better backend.
    , ephemeralUID : Int
    -- Move this into the Sheet Model
    , editMode : Bool
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
