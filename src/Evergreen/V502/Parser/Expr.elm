module Evergreen.V502.Parser.Expr exposing (..)

import Evergreen.V502.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V502.Parser.Meta.Meta
    | Text String Evergreen.V502.Parser.Meta.Meta
    | Verbatim String String Evergreen.V502.Parser.Meta.Meta
