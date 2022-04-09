module Evergreen.V304.Parser.Expr exposing (..)

import Evergreen.V304.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V304.Parser.Meta.Meta
    | Text String Evergreen.V304.Parser.Meta.Meta
    | Verbatim String String Evergreen.V304.Parser.Meta.Meta
