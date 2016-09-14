module ExerciseSheet exposing (..)

import Http
import Json.Decode as Json exposing ((:=))
import Task
import Set exposing (Set)
import List.Extra exposing (replaceIf, uniqueBy)
import Exercise exposing (..)


extractUID : Exercise -> Int
extractUID exercise =
    exercise.uid


{-| The LazySheet provides summary Information about a sheet like its name
    and its uid. However the LazySheet is not fully loaded yet, in particular
    the exercises are missing.
-}
type alias LazySheet =
    { uid : Int
    , title : String
    }


decodeExercise =
    Json.object3 buildExercise
        ("title" := Json.string)
        ("text" := Json.string)
        ("uid" := Json.int)


decodeSheet : Json.Decoder ExerciseSheet
decodeSheet =
    decodeExerciseList


decodeExerciseList =
    Json.object1 fromList
        ("exercises" := Json.list decodeExercise)


decodeSheetList : Json.Decoder (List LazySheet)
decodeSheetList =
    "sheets"
        := (Json.list
                (Json.object2 LazySheet
                    ("uid" := Json.int)
                    ("title" := Json.string)
                )
           )


load lsheet =
    Http.get decodeSheet ("./api/sheet/" ++ toString lsheet.uid ++ ".json")


loadSheetList =
    Http.get decodeSheetList "./api/sheets.json"


type alias ExerciseSheet =
    { list : List Exercise
    , set : Set Int
    }


fromList : List Exercise -> ExerciseSheet
fromList list =
    let
        list' =
            uniqueBy extractUID list

        set =
            Set.fromList <| List.map extractUID list'
    in
        ExerciseSheet list set


remove : Int -> ExerciseSheet -> ExerciseSheet
remove uid box =
    let
        list =
            List.filter (extractUID >> ((/=) uid)) box.list

        set =
            Set.remove uid box.set
    in
        ExerciseSheet list set


insert : Exercise -> ExerciseSheet -> ExerciseSheet
insert element box =
    if Set.member element.uid box.set then
        { box
            | list = replaceIf (extractUID >> ((==) element.uid)) element box.list
        }
    else
        ExerciseSheet
            (element :: box.list)
            (Set.insert element.uid box.set)


member : Int -> ExerciseSheet -> Bool
member uid box =
    Set.member uid box.set


find : Int -> ExerciseSheet -> Maybe Exercise
find uid box =
    List.Extra.find (extractUID >> ((==) uid)) box.list


length : ExerciseSheet -> Int
length box = List.length box.list
