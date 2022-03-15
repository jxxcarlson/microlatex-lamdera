module Evergreen.V102.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V102.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V102.Parser.Language.Language
    }
