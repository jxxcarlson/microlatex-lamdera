module Evergreen.V314.Parser.Expr exposing (..)

import Evergreen.V314.Parser.Meta


type Expr
    = Expr String (List Expr) Evergreen.V314.Parser.Meta.Meta
    | Text String Evergreen.V314.Parser.Meta.Meta
    | Verbatim String String Evergreen.V314.Parser.Meta.Meta
