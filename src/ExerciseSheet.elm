module ExerciseSheet exposing (..)

import Set exposing (Set)
import List.Extra exposing (replaceIf, uniqueBy)

import Exercise exposing (..)

extractUID : Exercise -> Int
extractUID exercise =
    exercise.uid


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
