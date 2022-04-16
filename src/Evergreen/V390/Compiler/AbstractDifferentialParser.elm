module Evergreen.V390.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V390.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V390.Parser.Language.Language
    , messages : List String
    }
