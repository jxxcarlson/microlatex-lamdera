module Evergreen.V425.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V425.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V425.Parser.Language.Language
    , messages : List String
    }
