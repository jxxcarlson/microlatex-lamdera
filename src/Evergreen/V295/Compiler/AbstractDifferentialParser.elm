module Evergreen.V295.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V295.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V295.Parser.Language.Language
    }
