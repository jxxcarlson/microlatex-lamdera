module Evergreen.V391.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V391.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V391.Parser.Language.Language
    , messages : List String
    }
