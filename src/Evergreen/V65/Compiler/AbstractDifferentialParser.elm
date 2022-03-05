module Evergreen.V65.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V65.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V65.Parser.Language.Language
    }
