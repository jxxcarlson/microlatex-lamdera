module Evergreen.V449.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V449.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V449.Parser.Language.Language
    , messages : List String
    }
