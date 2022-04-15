module Evergreen.V375.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V375.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V375.Parser.Language.Language
    , messages : List String
    }
