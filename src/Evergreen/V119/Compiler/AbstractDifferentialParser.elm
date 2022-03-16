module Evergreen.V119.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V119.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V119.Parser.Language.Language
    }
