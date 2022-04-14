module Evergreen.V374.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V374.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V374.Parser.Language.Language
    , messages : List String
    }
