module Evergreen.V684.Parser.Expr exposing (..)

import Evergreen.V684.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V684.Parser.Meta.Meta
    | Text String Evergreen.V684.Parser.Meta.Meta
    | Verbatim String String Evergreen.V684.Parser.Meta.Meta
