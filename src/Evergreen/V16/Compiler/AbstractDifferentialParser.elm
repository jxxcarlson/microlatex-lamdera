module Evergreen.V16.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V16.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V16.Parser.Language.Language
    }
