module Evergreen.V148.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V148.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V148.Parser.Language.Language
    }
