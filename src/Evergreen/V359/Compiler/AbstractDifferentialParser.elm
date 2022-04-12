module Evergreen.V359.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V359.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V359.Parser.Language.Language
    }
