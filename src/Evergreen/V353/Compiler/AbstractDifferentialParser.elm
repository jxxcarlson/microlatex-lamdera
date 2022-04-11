module Evergreen.V353.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V353.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V353.Parser.Language.Language
    }
