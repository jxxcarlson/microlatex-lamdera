module Evergreen.V195.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V195.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V195.Parser.Language.Language
    }
