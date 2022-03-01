module Evergreen.V24.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V24.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V24.Parser.Language.Language
    }
