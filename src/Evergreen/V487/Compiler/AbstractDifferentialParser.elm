module Evergreen.V487.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V487.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V487.Parser.Language.Language
    , messages : List String
    }
