module Evergreen.V81.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V81.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V81.Parser.Language.Language
    }
