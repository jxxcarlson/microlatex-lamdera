module Evergreen.V225.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V225.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V225.Parser.Language.Language
    }
