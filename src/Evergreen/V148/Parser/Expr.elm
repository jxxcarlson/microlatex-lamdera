module Evergreen.V148.Parser.Expr exposing (..)

import Evergreen.V148.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V148.Parser.Meta.Meta
    | Text String Evergreen.V148.Parser.Meta.Meta
    | Verbatim String String Evergreen.V148.Parser.Meta.Meta
