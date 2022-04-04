module Evergreen.V246.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V246.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V246.Parser.Language.Language
    }
