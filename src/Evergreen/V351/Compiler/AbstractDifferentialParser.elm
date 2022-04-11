module Evergreen.V351.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V351.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V351.Parser.Language.Language
    }
