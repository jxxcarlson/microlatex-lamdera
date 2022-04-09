module Evergreen.V304.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V304.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V304.Parser.Language.Language
    }
