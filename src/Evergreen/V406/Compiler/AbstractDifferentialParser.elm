module Evergreen.V406.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V406.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V406.Parser.Language.Language
    , messages : List String
    }
