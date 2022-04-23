module Evergreen.V476.Parser.Expr exposing (..)

import Evergreen.V476.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V476.Parser.Meta.Meta
    | Text String Evergreen.V476.Parser.Meta.Meta
    | Verbatim String String Evergreen.V476.Parser.Meta.Meta
