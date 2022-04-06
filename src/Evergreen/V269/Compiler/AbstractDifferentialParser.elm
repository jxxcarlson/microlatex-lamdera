module Evergreen.V269.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V269.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V269.Parser.Language.Language
    }
