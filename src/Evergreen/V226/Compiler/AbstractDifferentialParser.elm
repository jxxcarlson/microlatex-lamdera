module Evergreen.V226.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V226.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V226.Parser.Language.Language
    }
