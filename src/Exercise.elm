module Exercise exposing (..)


type alias Exercise =
    { title : String
    , text : String
    , uid :
        Int
        -- The interface has at most one active container (The current Worksheet).
    , inActiveContainer : Bool
    }
