module Evergreen.V221.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V221.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V221.Parser.Language.Language
    }
