module Evergreen.V13.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V13.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V13.Parser.Language.Language
    }
