module Evergreen.V377.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V377.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V377.Parser.Language.Language
    , messages : List String
    }
