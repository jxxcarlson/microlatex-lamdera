module Evergreen.V494.Compiler.Acc exposing (..)

import Dict
import Evergreen.V494.Compiler.Lambda
import Evergreen.V494.Compiler.Vector
import Evergreen.V494.Parser.MathMacro


type alias TermLoc =
    { begin : Int
    , end : Int
    , id : String
    }


type alias Accumulator =
    { headingIndex : Evergreen.V494.Compiler.Vector.Vector
    , documentIndex : Evergreen.V494.Compiler.Vector.Vector
    , counter : Dict.Dict String Int
    , itemVector : Evergreen.V494.Compiler.Vector.Vector
    , numberedItemDict :
        Dict.Dict
            String
            { level : Int
            , index : Int
            }
    , numberedBlockNames : List String
    , environment : Dict.Dict String Evergreen.V494.Compiler.Lambda.Lambda
    , inList : Bool
    , reference :
        Dict.Dict
            String
            { id : String
            , numRef : String
            }
    , terms : Dict.Dict String TermLoc
    , mathMacroDict : Evergreen.V494.Parser.MathMacro.MathMacroDict
    }
