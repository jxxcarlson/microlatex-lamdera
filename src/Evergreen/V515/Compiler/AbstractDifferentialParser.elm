module Evergreen.V515.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V515.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V515.Parser.Language.Language
    , messages : List String
    , includedFiles : List String
    }
