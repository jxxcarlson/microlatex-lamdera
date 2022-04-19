module Evergreen.V416.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V416.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V416.Parser.Language.Language
    , messages : List String
    }
