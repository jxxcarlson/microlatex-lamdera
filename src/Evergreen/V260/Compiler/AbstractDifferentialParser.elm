module Evergreen.V260.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V260.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V260.Parser.Language.Language
    }
