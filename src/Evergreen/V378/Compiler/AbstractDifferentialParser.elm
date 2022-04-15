module Evergreen.V378.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V378.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V378.Parser.Language.Language
    , messages : List String
    }
