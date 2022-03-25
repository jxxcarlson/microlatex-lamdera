module Evergreen.V157.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V157.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V157.Parser.Language.Language
    }
