module Evergreen.V281.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V281.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V281.Parser.Language.Language
    }
