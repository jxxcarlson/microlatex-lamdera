module Evergreen.V225.Parser.Expr exposing (..)

import Evergreen.V225.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V225.Parser.Meta.Meta
    | Text String Evergreen.V225.Parser.Meta.Meta
    | Verbatim String String Evergreen.V225.Parser.Meta.Meta
