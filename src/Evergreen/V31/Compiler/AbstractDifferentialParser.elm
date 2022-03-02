module Evergreen.V31.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V31.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V31.Parser.Language.Language
    }
