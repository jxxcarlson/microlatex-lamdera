module Evergreen.V447.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V447.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V447.Parser.Language.Language
    , messages : List String
    }
