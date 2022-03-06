module Evergreen.V77.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V77.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V77.Parser.Language.Language
    }
