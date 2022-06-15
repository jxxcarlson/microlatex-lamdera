module Evergreen.V631.Parser.Expr exposing (..)

import Evergreen.V631.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V631.Parser.Meta.Meta
    | Text String Evergreen.V631.Parser.Meta.Meta
    | Verbatim String String Evergreen.V631.Parser.Meta.Meta
