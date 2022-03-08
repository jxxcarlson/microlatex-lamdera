module Evergreen.V82.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V82.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V82.Parser.Language.Language
    }
