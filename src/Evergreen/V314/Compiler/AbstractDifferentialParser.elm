module Evergreen.V314.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V314.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V314.Parser.Language.Language
    }
