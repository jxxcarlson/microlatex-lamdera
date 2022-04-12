module Evergreen.V360.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V360.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V360.Parser.Language.Language
    }
