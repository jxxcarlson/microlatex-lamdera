module Evergreen.V710.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V710.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V710.Parser.Language.Language
    , messages : List String
    , includedFiles : List String
    }
