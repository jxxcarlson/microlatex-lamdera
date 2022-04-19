module Evergreen.V418.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V418.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V418.Parser.Language.Language
    , messages : List String
    }
