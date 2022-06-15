module Evergreen.V631.Debounce exposing (..)


type Msg
    = NoOp
    | Flush (Maybe Float)
    | SendIfLengthNotChangedFrom Int


type Debounce a
    = Debounce
        { input : List a
        , locked : Bool
        }
