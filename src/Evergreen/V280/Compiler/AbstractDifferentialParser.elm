module Evergreen.V280.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V280.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V280.Parser.Language.Language
    }
