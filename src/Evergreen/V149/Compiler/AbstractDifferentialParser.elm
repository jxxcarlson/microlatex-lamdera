module Evergreen.V149.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V149.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V149.Parser.Language.Language
    }
