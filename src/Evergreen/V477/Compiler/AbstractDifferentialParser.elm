module Evergreen.V477.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V477.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V477.Parser.Language.Language
    , messages : List String
    }
