module Evergreen.V337.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V337.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V337.Parser.Language.Language
    }
