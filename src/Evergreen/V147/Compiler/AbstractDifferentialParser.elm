module Evergreen.V147.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V147.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V147.Parser.Language.Language
    }
