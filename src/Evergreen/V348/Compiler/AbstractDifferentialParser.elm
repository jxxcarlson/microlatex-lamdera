module Evergreen.V348.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V348.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V348.Parser.Language.Language
    }
