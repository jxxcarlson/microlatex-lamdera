module Evergreen.V310.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V310.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V310.Parser.Language.Language
    }
