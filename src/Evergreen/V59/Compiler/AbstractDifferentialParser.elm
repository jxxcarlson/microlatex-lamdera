module Evergreen.V59.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V59.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V59.Parser.Language.Language
    }
