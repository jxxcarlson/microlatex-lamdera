module Evergreen.V277.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V277.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V277.Parser.Language.Language
    }
