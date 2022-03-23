module Evergreen.V152.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V152.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V152.Parser.Language.Language
    }
