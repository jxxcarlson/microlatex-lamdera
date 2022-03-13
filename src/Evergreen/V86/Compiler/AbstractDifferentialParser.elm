module Evergreen.V86.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V86.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V86.Parser.Language.Language
    }
