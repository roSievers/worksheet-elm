module Exercise exposing (..)


type alias Exercise =
    { title : String
    , text : String
    , uid :
        Int
        -- The interface has at most one active container (The current Worksheet).
    , inActiveContainer : Bool
    }


blankExercise =
    (Exercise "" "" -1 False)


buildExercise title text uid =
    { blankExercise | title = title, text = text, uid = uid }
