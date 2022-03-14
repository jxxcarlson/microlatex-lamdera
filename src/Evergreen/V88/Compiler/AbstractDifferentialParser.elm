module Evergreen.V88.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V88.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V88.Parser.Language.Language
    }
