module Evergreen.V396.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V396.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V396.Parser.Language.Language
    , messages : List String
    }
