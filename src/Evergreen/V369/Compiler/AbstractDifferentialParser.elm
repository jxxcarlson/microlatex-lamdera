module Evergreen.V369.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V369.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V369.Parser.Language.Language
    , messages : List String
    }
