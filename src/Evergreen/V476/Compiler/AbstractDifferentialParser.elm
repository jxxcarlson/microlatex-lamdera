module Evergreen.V476.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V476.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V476.Parser.Language.Language
    , messages : List String
    }
