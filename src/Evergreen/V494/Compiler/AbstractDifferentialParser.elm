module Evergreen.V494.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V494.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V494.Parser.Language.Language
    , messages : List String
    }
