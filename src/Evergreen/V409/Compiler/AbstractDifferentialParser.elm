module Evergreen.V409.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V409.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V409.Parser.Language.Language
    , messages : List String
    }
