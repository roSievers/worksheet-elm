module Exercise exposing (..)


type alias Exercise =
    { title : String
    , text : String
    , uid : Int
    }


blankExercise =
    (Exercise "" "" -1)


buildExercise title text uid =
    { blankExercise | title = title, text = text, uid = uid }
