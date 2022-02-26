module Evergreen.V7.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V7.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V7.Parser.Language.Language
    }
