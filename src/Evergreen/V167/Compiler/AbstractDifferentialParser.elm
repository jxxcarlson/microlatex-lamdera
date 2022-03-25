module Evergreen.V167.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V167.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V167.Parser.Language.Language
    }
