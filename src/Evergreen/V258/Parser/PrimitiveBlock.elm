module Evergreen.V258.Parser.PrimitiveBlock exposing (..)

import Evergreen.V258.Parser.Line


type alias PrimitiveBlock =
    { indent : Int
    , lineNumber : Int
    , position : Int
    , content : List String
    , name : Maybe String
    , args : List String
    , named : Bool
    , sourceText : String
    , blockType : Evergreen.V258.Parser.Line.PrimitiveBlockType
    }
