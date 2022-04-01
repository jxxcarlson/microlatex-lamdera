module Evergreen.V198.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V198.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V198.Parser.Language.Language
    }
