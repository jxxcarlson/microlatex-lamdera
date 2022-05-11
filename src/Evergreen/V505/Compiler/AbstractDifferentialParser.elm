module Evergreen.V505.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V505.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V505.Parser.Language.Language
    , messages : List String
    , includedFiles : List String
    }
