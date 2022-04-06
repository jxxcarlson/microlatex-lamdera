module Evergreen.V273.Parser.Expr exposing (..)

import Evergreen.V273.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V273.Parser.Meta.Meta
    | Text String Evergreen.V273.Parser.Meta.Meta
    | Verbatim String String Evergreen.V273.Parser.Meta.Meta
