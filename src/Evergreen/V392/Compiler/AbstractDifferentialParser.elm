module Evergreen.V392.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V392.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V392.Parser.Language.Language
    , messages : List String
    }
