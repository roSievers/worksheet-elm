module ExerciseSheet exposing (..)

import Http
import Json.Decode exposing ((:=))
import Json.Encode
import Task exposing (Task)
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


decodeSheet : Json.Decode.Decoder ExerciseSheet
decodeSheet =
    Json.Decode.object3 fromList
        ("uid" := Json.Decode.int)
        ("title" := Json.Decode.string)
        ("exercises" := Json.Decode.list decodeExercise)


encodeUID exercise =
    Json.Encode.int (exercise.uid)


encodeSheet : ExerciseSheet -> String
encodeSheet sheet =
    Json.Encode.encode 0 <|
        Json.Encode.object
            [ ( "title", Json.Encode.string sheet.title )
            , ( "content"
              , Json.Encode.list
                    (List.map encodeUID sheet.list)
              )
            , ( "uid", Json.Encode.int sheet.uid )
            ]


decodeSheetList : Json.Decode.Decoder (List LazySheet)
decodeSheetList =
    "sheets"
        := (Json.Decode.list
                (Json.Decode.object2 LazySheet
                    ("uid" := Json.Decode.int)
                    ("title" := Json.Decode.string)
                )
           )


decodeConfirmation : Json.Decode.Decoder ()
decodeConfirmation =
    ("status" := Json.Decode.string)
        `Json.Decode.andThen`
            \status ->
                if status == "ok" then
                    Json.Decode.succeed ()
                else
                    Json.Decode.fail ("Status code was: '" ++ status ++ "'.")


load : LazySheet -> Task Http.Error ExerciseSheet
load lsheet =
    Http.get decodeSheet ("http://localhost:8010/api/sheet/" ++ toString lsheet.uid)


update : ExerciseSheet -> Task Http.Error ()
update sheet =
    Http.post
        decodeConfirmation
        ("http://localhost:8010/api/sheet/" ++ (toString sheet.uid))
        (sheet |> encodeSheet |> Http.string)


loadSheetList =
    Http.get decodeSheetList "http://localhost:8010/api/sheets"


{-| Synchonisation of the ExerciseSheet waits until a few seconds have passed
without any changes before it does an autosave. The Delayed SyncState is used
to represent this.

If the data is changed while syncronisation is still running, SyncingOutdated
can be used to indicate this.

A AutosaveTick moves a Delayed state to ReadyToSync, but actual syncronisation
waits for another tick. Edits revert ReadyToSync back to Delayed.
-}
type SyncState
    = UpToDate
    | Delayed
    | ReadyToSync
    | Syncing
    | SyncingOutdated
    | SyncError


type alias ExerciseSheet =
    { uid : Int
    , list : List Exercise
    , set : Set Int
    , title : String
    , syncState : SyncState
    }


fromList : Int -> String -> List Exercise -> ExerciseSheet
fromList uid title list =
    let
        list' =
            uniqueBy extractUID list

        set =
            Set.fromList <| List.map extractUID list'
    in
        ExerciseSheet uid list set title UpToDate


remove : Int -> ExerciseSheet -> ExerciseSheet
remove uid sheet =
    let
        list =
            List.filter (extractUID >> ((/=) uid)) sheet.list

        set =
            Set.remove uid sheet.set
    in
        { sheet
            | list = list
            , set = set
        }


insert : Exercise -> ExerciseSheet -> ExerciseSheet
insert element sheet =
    if Set.member element.uid sheet.set then
        { sheet
            | list = replaceIf (extractUID >> ((==) element.uid)) element sheet.list
        }
    else
        { sheet
            | list = (element :: sheet.list)
            , set = (Set.insert element.uid sheet.set)
        }


member : Int -> ExerciseSheet -> Bool
member uid sheet =
    Set.member uid sheet.set


find : Int -> ExerciseSheet -> Maybe Exercise
find uid sheet =
    List.Extra.find (extractUID >> ((==) uid)) sheet.list


length : ExerciseSheet -> Int
length sheet =
    List.length sheet.list


dirty : ExerciseSheet -> ExerciseSheet
dirty sheet =
    { sheet
        | syncState =
            case sheet.syncState of
                UpToDate ->
                    Delayed

                Delayed ->
                    Delayed

                ReadyToSync ->
                    Delayed

                Syncing ->
                    SyncingOutdated

                SyncingOutdated ->
                    SyncingOutdated

                SyncError ->
                    SyncError
    }


autosaveTick : ExerciseSheet -> ( ExerciseSheet, Bool )
autosaveTick sheet =
    let
        ( newSyncState, doSave ) =
            case sheet.syncState of
                UpToDate ->
                    ( UpToDate, False )

                Delayed ->
                    ( ReadyToSync, False )

                ReadyToSync ->
                    ( Syncing, True )

                Syncing ->
                    ( Syncing, False )

                SyncingOutdated ->
                    ( SyncingOutdated, False )

                SyncError ->
                    ( Syncing, True )
    in
        ( { sheet
            | syncState = newSyncState
          }
        , doSave
        )


saveDone : ExerciseSheet -> ExerciseSheet
saveDone sheet =
    { sheet
        | syncState =
            case sheet.syncState of
                UpToDate ->
                    UpToDate

                Delayed ->
                    Delayed -- illegal state

                ReadyToSync ->
                    ReadyToSync -- illegal state

                Syncing ->
                    UpToDate

                SyncingOutdated ->
                    Delayed

                SyncError ->
                    SyncError -- What does this represent?
    }
