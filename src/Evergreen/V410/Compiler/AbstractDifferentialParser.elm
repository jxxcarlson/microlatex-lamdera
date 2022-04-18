module Evergreen.V410.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V410.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V410.Parser.Language.Language
    , messages : List String
    }
