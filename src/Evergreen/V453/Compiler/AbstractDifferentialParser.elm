module Evergreen.V453.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V453.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V453.Parser.Language.Language
    , messages : List String
    }
