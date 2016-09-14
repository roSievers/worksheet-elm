module Requests exposing (requestExerciseList)

import Http
import Json.Decode as Json exposing ((:=))
import Task
import Events exposing (..)
import Exercise exposing (..)


-- Decoding Exercises


decodeExercise =
    Json.object3 buildExercise
        ("title" := Json.string)
        ("text" := Json.string)
        ("uid" := Json.int)


decodeExerciseList : Json.Decoder (List Exercise)
decodeExerciseList =
    ("exercises" := Json.list decodeExercise)



-- Requesting Exercises


requestExerciseList : (List Exercise -> Msg) -> String -> Cmd Msg
requestExerciseList successMessage url =
    Http.get decodeExerciseList url
        |> Task.perform LoadingFail successMessage
