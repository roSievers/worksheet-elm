module Exercise exposing (..)

import Http
import Json.Decode exposing ((:=))
import Json.Encode
import Task exposing (Task)


type alias Exercise =
    { title : String
    , text : String
    , uid : Int
    }


blankExercise =
    (Exercise "" "" -1)


buildExercise title text uid =
    { blankExercise | title = title, text = text, uid = uid }


decodeExercise =
    Json.Decode.object3 Exercise
        ("title" := Json.Decode.string)
        ("text" := Json.Decode.string)
        ("uid" := Json.Decode.int)


encodeExercise : Exercise -> String
encodeExercise exercise =
    Json.Encode.encode 0 <|
        Json.Encode.object
            [ ( "title", Json.Encode.string exercise.title )
            , ( "text", Json.Encode.string exercise.text )
            , ( "uid", Json.Encode.int exercise.uid )
            ]


{-| The updateExercise task can either update an existing exercise when given
    a positive uid or create a new one when given -1 as uid. The switch for this
    is implemented in the backend.

    A new Exercise is returned, this contains correct uid instead of -1.
-}
updateExercise : Exercise -> Task Http.Error Exercise
updateExercise exercise =
    Http.post
        decodeExercise
        ("http://localhost:8010/api/exercise/" ++ (toString exercise.uid))
        (exercise |> encodeExercise |> Http.string)
