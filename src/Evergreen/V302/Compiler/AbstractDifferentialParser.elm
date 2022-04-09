module Evergreen.V302.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V302.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V302.Parser.Language.Language
    }
