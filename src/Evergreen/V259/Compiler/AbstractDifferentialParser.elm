module Evergreen.V259.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V259.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V259.Parser.Language.Language
    }
