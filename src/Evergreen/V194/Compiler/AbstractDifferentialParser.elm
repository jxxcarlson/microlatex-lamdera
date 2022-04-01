module Evergreen.V194.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V194.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V194.Parser.Language.Language
    }
