module Evergreen.V428.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V428.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V428.Parser.Language.Language
    , messages : List String
    }
