module Evergreen.V99.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V99.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V99.Parser.Language.Language
    }
