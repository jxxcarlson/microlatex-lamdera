module Evergreen.V236.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V236.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V236.Parser.Language.Language
    }
