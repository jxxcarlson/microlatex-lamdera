module Evergreen.V288.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V288.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V288.Parser.Language.Language
    }
