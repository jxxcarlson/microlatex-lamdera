module Evergreen.V374.Parser.PrimitiveBlock exposing (..)

import Evergreen.V374.Parser.Line


type alias PrimitiveBlock =
    { indent : Int
    , lineNumber : Int
    , position : Int
    , content : List String
    , name : Maybe String
    , args : List String
    , named : Bool
    , sourceText : String
    , blockType : Evergreen.V374.Parser.Line.PrimitiveBlockType
    }
