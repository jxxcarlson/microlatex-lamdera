module Evergreen.V405.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V405.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V405.Parser.Language.Language
    , messages : List String
    }
