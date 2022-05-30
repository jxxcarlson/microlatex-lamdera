module Evergreen.V533.Compiler.Acc exposing (..)

import Dict
import Evergreen.V533.Compiler.Lambda
import Evergreen.V533.Compiler.Vector
import Evergreen.V533.Parser.MathMacro


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V533.Compiler.Vector.Vector
    , documentIndex : Evergreen.V533.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , itemVector : Evergreen.V533.Compiler.Vector.Vector
    , numberedItemDict :
        Dict.Dict
            String
            { level : Int
            , index : Int
            }
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V533.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    , mathMacroDict : Evergreen.V533.Parser.MathMacro.MathMacroDict
    }
