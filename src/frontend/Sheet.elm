module Sheet exposing (..)

import Http
import Json.Decode exposing ((:=))
import Json.Encode
import Task exposing (Task)
import Set exposing (Set)
import List.Extra exposing (replaceIf, uniqueBy)
import Time exposing (Time)
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


decodeSheet : Json.Decode.Decoder Sheet
decodeSheet =
    Json.Decode.object3 fromList
        ("uid" := Json.Decode.int)
        ("title" := Json.Decode.string)
        ("exercises" := Json.Decode.list decodeExercise)


encodeUID exercise =
    Json.Encode.int (exercise.uid)


encodeSheet : Sheet -> String
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


load : LazySheet -> Task Http.Error Sheet
load lsheet =
    Http.get decodeSheet ("http://localhost:8010/api/sheet/" ++ toString lsheet.uid)


update : Sheet -> Task Http.Error ()
update sheet =
    Http.post
        decodeConfirmation
        ("http://localhost:8010/api/sheet/" ++ (toString sheet.uid))
        (sheet |> encodeSheet |> Http.string)


loadSheetList =
    Http.get decodeSheetList "http://localhost:8010/api/sheets"


{-| Synchonisation of the Sheet waits until a few seconds have passed
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


type alias Sheet =
    { uid : Int
    , list : List Exercise
    , set : Set Int
    , title : String
    , syncState :
        SyncState
        -- This is meta information that should be located elsewhere...
    , lastSave : Maybe Time
    }


fromList : Int -> String -> List Exercise -> Sheet
fromList uid title list =
    let
        list' =
            uniqueBy extractUID list

        set =
            Set.fromList <| List.map extractUID list'
    in
        Sheet uid list set title UpToDate Nothing


remove : Int -> Sheet -> Sheet
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


insert : Exercise -> Sheet -> Sheet
insert element sheet =
    if Set.member element.uid sheet.set then
        { sheet
            | list = replaceIf (extractUID >> ((==) element.uid)) element sheet.list
        }
    else
        { sheet
            | list = element :: sheet.list
            , set = Set.insert element.uid sheet.set
        }


insertAt : Int -> Exercise -> Sheet -> Sheet
insertAt index element sheet =
    if Set.member element.uid sheet.set then
        {- If the exercise is already present then insertAt has to move the it.
           The tricky part is avoiding of by one errors, as the element
           vannishes at another location.
        -}
        let
            ( head, tail ) =
                List.Extra.splitAt index sheet.list

            cleanHead =
                List.filter (extractUID >> ((/=) element.uid)) head

            cleanTail =
                List.filter (extractUID >> ((/=) element.uid)) tail
        in
            { sheet
                | list = List.append cleanHead (element :: cleanTail)
                , set = sheet.set
            }
    else
        { sheet
            | list = listInsertAt index element sheet.list
            , set = Set.insert element.uid sheet.set
        }


replaceOldUID : Int -> Exercise -> Sheet -> Sheet
replaceOldUID oldUID element sheet =
    let
        list =
            List.Extra.updateIf
                (extractUID >> ((==) oldUID))
                (\_ -> element)
                sheet.list

        set =
            sheet.set
                |> Set.remove oldUID
                |> Set.insert element.uid
    in
        { sheet
            | list = list
            , set = set
        }


switchPosition : Int -> Int -> Sheet -> Sheet
switchPosition first second sheet =
    let
        maybeNewList =
            swapAt first second sheet.list
    in
        { sheet | list = Maybe.withDefault sheet.list maybeNewList }


{-| I have opened a pull request for swapAt with list-extra.
-}
swapAt : Int -> Int -> List a -> Maybe (List a)
swapAt index1 index2 l =
    if index1 == index2 then
        Just l
    else if index1 > index2 then
        swapAt index2 index1 l
    else if index1 < 0 then
        Nothing
    else
        let
            ( part1, tail1 ) =
                List.Extra.splitAt index1 l

            ( head2, tail2 ) =
                List.Extra.splitAt (index2 - index1) tail1
        in
            Maybe.map2
                (\( value1, part2 ) ( value2, part3 ) ->
                    List.concat [ part1, value2 :: part2, value1 :: part3 ]
                )
                (List.Extra.uncons head2)
                (List.Extra.uncons tail2)


{-| This really belongs into List.Extra
-}
listInsertAt : Int -> a -> List a -> List a
listInsertAt index value list =
    let
        ( head, tail ) =
            List.Extra.splitAt index list
    in
        List.append head (value :: tail)


member : Int -> Sheet -> Bool
member uid sheet =
    Set.member uid sheet.set


find : Int -> Sheet -> Maybe Exercise
find uid sheet =
    List.Extra.find (extractUID >> ((==) uid)) sheet.list


length : Sheet -> Int
length sheet =
    List.length sheet.list


dirty : Sheet -> Sheet
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


autosaveTick : Sheet -> ( Sheet, Bool )
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


saveDone : Time -> Sheet -> Sheet
saveDone time sheet =
    { sheet
        | syncState =
            case sheet.syncState of
                UpToDate ->
                    UpToDate

                -- illegal state
                Delayed ->
                    Delayed

                -- illegal state
                ReadyToSync ->
                    ReadyToSync

                Syncing ->
                    UpToDate

                SyncingOutdated ->
                    Delayed

                -- What does this represent?
                SyncError ->
                    SyncError
        , lastSave = Just time
    }
