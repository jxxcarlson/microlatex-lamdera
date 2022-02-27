module Evergreen.V12.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V12.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V12.Parser.Language.Language
    }
