module Evergreen.V154.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V154.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V154.Parser.Language.Language
    }
