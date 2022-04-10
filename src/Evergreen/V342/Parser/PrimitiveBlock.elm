module Evergreen.V342.Parser.PrimitiveBlock exposing (..)

import Evergreen.V342.Parser.Line


type alias PrimitiveBlock =
    { indent : Int
    , lineNumber : Int
    , position : Int
    , content : List String
    , name : Maybe String
    , args : List String
    , named : Bool
    , sourceText : String
    , blockType : Evergreen.V342.Parser.Line.PrimitiveBlockType
    }
