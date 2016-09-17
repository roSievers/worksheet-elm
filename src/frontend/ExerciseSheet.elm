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


decodeSheet : Json.Decoder ExerciseSheet
decodeSheet =
    decodeExerciseList


decodeExerciseList =
    Json.object2 fromList
        ("title" := Json.string)
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
    Http.get decodeSheet ("http://localhost:8010/api/sheet/" ++ toString lsheet.uid)


loadSheetList =
    Http.get decodeSheetList "http://localhost:8010/api/sheets"


type alias ExerciseSheet =
    { list : List Exercise
    , set : Set Int
    , title : String
    }


fromList : String -> List Exercise -> ExerciseSheet
fromList title list =
    let
        list' =
            uniqueBy extractUID list

        set =
            Set.fromList <| List.map extractUID list'
    in
        ExerciseSheet list set title


remove : Int -> ExerciseSheet -> ExerciseSheet
remove uid box =
    let
        list =
            List.filter (extractUID >> ((/=) uid)) box.list

        set =
            Set.remove uid box.set
    in
        { box
            | list = list
            , set = set
        }


insert : Exercise -> ExerciseSheet -> ExerciseSheet
insert element box =
    if Set.member element.uid box.set then
        { box
            | list = replaceIf (extractUID >> ((==) element.uid)) element box.list
        }
    else
        { box
            | list = (element :: box.list)
            , set = (Set.insert element.uid box.set)}


member : Int -> ExerciseSheet -> Bool
member uid box =
    Set.member uid box.set


find : Int -> ExerciseSheet -> Maybe Exercise
find uid box =
    List.Extra.find (extractUID >> ((==) uid)) box.list


length : ExerciseSheet -> Int
length box =
    List.length box.list
