module Evergreen.V316.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V316.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V316.Parser.Language.Language
    }
