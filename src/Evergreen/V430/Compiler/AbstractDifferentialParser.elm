module Evergreen.V430.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V430.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V430.Parser.Language.Language
    , messages : List String
    }
