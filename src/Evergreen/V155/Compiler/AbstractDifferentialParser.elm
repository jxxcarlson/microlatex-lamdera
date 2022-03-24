module Evergreen.V155.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V155.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V155.Parser.Language.Language
    }
