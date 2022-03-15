module Evergreen.V103.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V103.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V103.Parser.Language.Language
    }
