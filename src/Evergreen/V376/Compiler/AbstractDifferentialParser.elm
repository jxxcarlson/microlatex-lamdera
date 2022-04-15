module Evergreen.V376.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V376.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V376.Parser.Language.Language
    , messages : List String
    }
