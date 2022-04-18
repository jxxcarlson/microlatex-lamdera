module Evergreen.V399.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V399.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V399.Parser.Language.Language
    , messages : List String
    }
