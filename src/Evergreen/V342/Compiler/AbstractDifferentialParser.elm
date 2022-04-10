module Evergreen.V342.Compiler.AbstractDifferentialParser exposing (..)

import Evergreen.V342.Parser.Language


type alias EditRecord chunk parsedChunk accumulator =
    { chunks : List chunk
    , parsed : List parsedChunk
    , accumulator : accumulator
    , lang : Evergreen.V342.Parser.Language.Language
    }
