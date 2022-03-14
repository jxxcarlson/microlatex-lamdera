module Evergreen.V92.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V92.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V92.Parser.Language.Language
    }
